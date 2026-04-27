import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Messages } from '../../i18n';
import { BookingStatus, RoomStatus } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getRevenue(msg: Messages, query: { startDate: string; endDate: string; propertyId?: string; period?: string }) {
    const where: any = {
      status: BookingStatus.CHECKED_OUT,
      checkoutDate: {
        gte: new Date(query.startDate),
        lte: new Date(query.endDate),
      },
    };
    if (query.propertyId) {
      where.room = { propertyId: query.propertyId };
    }

    const bookings = await this.prisma.booking.findMany({
      where,
      select: { totalPrice: true, checkoutDate: true },
    });

    const totalRevenue = bookings.reduce((sum, b) => sum + Number(b.totalPrice), 0);

    return {
      message: msg.reports.revenueSuccess,
      data: { totalRevenue, bookingCount: bookings.length },
    };
  }

  async getOccupancy(msg: Messages, query: { startDate: string; endDate: string; propertyId?: string }) {
    const roomWhere: any = { isActive: true };
    if (query.propertyId) roomWhere.propertyId = query.propertyId;

    const totalRooms = await this.prisma.room.count({ where: roomWhere });

    const occupiedBookings = await this.prisma.booking.count({
      where: {
        status: { in: [BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN] },
        checkinDate: { lte: new Date(query.endDate) },
        checkoutDate: { gte: new Date(query.startDate) },
        ...(query.propertyId ? { room: { propertyId: query.propertyId } } : {}),
      },
    });

    const occupancyRate = totalRooms > 0 ? (occupiedBookings / totalRooms) * 100 : 0;

    return {
      message: msg.reports.occupancySuccess,
      data: { totalRooms, occupiedRooms: occupiedBookings, occupancyRate: Math.round(occupancyRate * 100) / 100 },
    };
  }

  async getBookingsSummary(msg: Messages, query: { startDate: string; endDate: string; propertyId?: string }) {
    const where: any = {
      createdAt: {
        gte: new Date(query.startDate),
        lte: new Date(query.endDate),
      },
    };
    if (query.propertyId) where.room = { propertyId: query.propertyId };

    const byStatus = await this.prisma.booking.groupBy({
      by: ['status'],
      where,
      _count: true,
    });

    const bySource = await this.prisma.booking.groupBy({
      by: ['source'],
      where,
      _count: true,
    });

    const total = byStatus.reduce((sum, s) => sum + s._count, 0);
    const cancelled = byStatus.find((s) => s.status === 'CANCELLED')?._count || 0;
    const cancellationRate = total > 0 ? (cancelled / total) * 100 : 0;

    return {
      message: msg.reports.bookingsSummarySuccess,
      data: { byStatus, bySource, total, cancellationRate: Math.round(cancellationRate * 100) / 100 },
    };
  }

  async getTopRooms(msg: Messages, query: { startDate: string; endDate: string; propertyId?: string; limit?: number }) {
    const where: any = {
      status: BookingStatus.CHECKED_OUT,
      checkoutDate: {
        gte: new Date(query.startDate),
        lte: new Date(query.endDate),
      },
    };
    if (query.propertyId) where.room = { propertyId: query.propertyId };

    const topRooms = await this.prisma.booking.groupBy({
      by: ['roomId'],
      where,
      _sum: { totalPrice: true },
      _count: true,
      orderBy: { _sum: { totalPrice: 'desc' } },
      take: query.limit || 10,
    });

    const roomIds = topRooms.map((r) => r.roomId);
    const rooms = await this.prisma.room.findMany({
      where: { id: { in: roomIds } },
      select: { id: true, name: true, property: { select: { name: true } } },
    });

    const data = topRooms.map((tr) => {
      const room = rooms.find((r) => r.id === tr.roomId);
      return {
        roomId: tr.roomId,
        roomName: room?.name,
        propertyName: room?.property?.name,
        totalRevenue: tr._sum.totalPrice,
        totalNights: tr._count,
      };
    });

    return { message: msg.reports.topRoomsSuccess, data };
  }

  async getDashboardStats(msg: Messages, propertyId?: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59);

    const roomWhere: any = { isActive: true };
    if (propertyId) roomWhere.propertyId = propertyId;

    const bookingWhere: any = {};
    if (propertyId) bookingWhere.room = { propertyId };

    // Today's revenue
    const todayPayments = await this.prisma.payment.aggregate({
      where: {
        status: 'COMPLETED',
        createdAt: { gte: today, lt: tomorrow },
        ...(propertyId ? { booking: { room: { propertyId } } } : {}),
      },
      _sum: { amount: true },
    });

    // Month's revenue
    const monthPayments = await this.prisma.payment.aggregate({
      where: {
        status: 'COMPLETED',
        createdAt: { gte: monthStart, lte: monthEnd },
        ...(propertyId ? { booking: { room: { propertyId } } } : {}),
      },
      _sum: { amount: true },
    });

    // Room status counts
    const rooms = await this.prisma.room.groupBy({
      by: ['status'],
      where: roomWhere,
      _count: true,
    });

    const roomsStatus = {
      vacant: rooms.find((r) => r.status === 'VACANT')?._count || 0,
      booked: rooms.find((r) => r.status === 'BOOKED')?._count || 0,
      occupied: rooms.find((r) => r.status === 'OCCUPIED')?._count || 0,
      maintenance: rooms.find((r) => r.status === 'MAINTENANCE')?._count || 0,
    };

    const totalRooms = Object.values(roomsStatus).reduce((a, b) => a + b, 0);
    const occupancyRate = totalRooms > 0
      ? ((roomsStatus.booked + roomsStatus.occupied) / totalRooms) * 100
      : 0;

    // Today's bookings
    const todayBookings = await this.prisma.booking.findMany({
      where: {
        ...bookingWhere,
        checkinDate: { gte: today, lt: tomorrow },
        status: { in: ['CONFIRMED', 'CHECKED_IN'] },
      },
      select: {
        id: true, bookingCode: true, status: true, guestCount: true,
        customer: { select: { fullName: true, phone: true } },
        room: { select: { name: true } },
      },
    });

    return {
      message: msg.reports.dashboardSuccess,
      data: {
        todayRevenue: Number(todayPayments._sum.amount || 0),
        monthRevenue: Number(monthPayments._sum.amount || 0),
        occupancyRate: Math.round(occupancyRate * 100) / 100,
        roomsStatus,
        todayBookings,
      },
    };
  }
}
