import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository, PaginationParams } from '../../common/repositories/base.repository';
import { BookingStatus, Prisma } from '@prisma/client';

@Injectable()
export class BookingsRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where: Prisma.BookingWhereInput, pagination?: PaginationParams) {
    const { skip, take, page, limit } = this.paginate(pagination);

    const [bookings, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          room: {
            select: {
              id: true, name: true,
              property: { select: { id: true, name: true } },
            },
          },
          customer: { select: { id: true, fullName: true, phone: true } },
          creator: { select: { id: true, fullName: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
      this.prisma.booking.count({ where }),
    ]);

    return { data: bookings, meta: { page, limit, total } };
  }

  async findById(id: string) {
    return this.prisma.booking.findUnique({
      where: { id },
      include: {
        room: {
          include: {
            property: { select: { id: true, name: true, address: true } },
            images: { orderBy: { sortOrder: 'asc' }, take: 5 },
          },
        },
        customer: true,
        creator: { select: { id: true, fullName: true, phone: true } },
        payments: { orderBy: { createdAt: 'desc' } },
      },
    });
  }

  async findRaw(id: string) {
    return this.prisma.booking.findUnique({ where: { id } });
  }

  async findRawWithRoom(id: string) {
    return this.prisma.booking.findUnique({
      where: { id },
      include: { room: { include: { property: true } } },
    });
  }

  async findRawWithCustomer(id: string) {
    return this.prisma.booking.findUnique({
      where: { id },
      include: { customer: true },
    });
  }

  async create(data: Prisma.BookingCreateInput) {
    return this.prisma.booking.create({
      data,
      include: {
        room: { select: { id: true, name: true } },
        customer: { select: { id: true, fullName: true, phone: true } },
      },
    });
  }

  async update(id: string, data: Prisma.BookingUpdateInput) {
    return this.prisma.booking.update({ where: { id }, data });
  }

  async delete(id: string) {
    return this.prisma.booking.delete({ where: { id } });
  }

  async cancelHoldsForRoom(roomId: string) {
    return this.prisma.booking.updateMany({
      where: { roomId, status: BookingStatus.HOLD },
      data: { status: BookingStatus.CANCELLED },
    });
  }

  async findConflicting(roomId: string, checkinDate: Date, checkoutDate: Date) {
    return this.prisma.booking.findFirst({
      where: {
        roomId,
        status: { in: [BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN] },
        checkinDate: { lt: checkoutDate },
        checkoutDate: { gt: checkinDate },
      },
    });
  }

  async findActiveHold(holdId: string) {
    return this.prisma.booking.findFirst({
      where: { id: holdId, status: BookingStatus.HOLD },
    });
  }

  async countTodayBookings() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return this.prisma.booking.count({
      where: { createdAt: { gte: today } },
    });
  }

  async findExpiredHolds() {
    return this.prisma.booking.findMany({
      where: {
        status: BookingStatus.HOLD,
        holdExpireAt: { lte: new Date() },
      },
    });
  }

  async cancelExpiredHolds(ids: string[]) {
    return this.prisma.booking.updateMany({
      where: { id: { in: ids } },
      data: { status: BookingStatus.CANCELLED },
    });
  }

  async countActiveForRoom(roomId: string) {
    return this.prisma.booking.count({
      where: {
        roomId,
        status: { in: ['HOLD', 'CONFIRMED', 'CHECKED_IN'] },
      },
    });
  }
}
