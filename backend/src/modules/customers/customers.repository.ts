import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository, PaginationParams } from '../../common/repositories/base.repository';
import { Prisma } from '@prisma/client';

@Injectable()
export class CustomersRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where: Prisma.CustomerWhereInput, pagination?: PaginationParams, orderBy?: Prisma.CustomerOrderByWithRelationInput) {
    const { skip, take, page, limit } = this.paginate(pagination);

    const [customers, total] = await Promise.all([
      this.prisma.customer.findMany({ where, orderBy, skip, take }),
      this.prisma.customer.count({ where }),
    ]);

    return { data: customers, meta: { page, limit, total } };
  }

  async findById(id: string) {
    return this.prisma.customer.findUnique({
      where: { id },
      include: {
        bookings: {
          orderBy: { createdAt: 'desc' },
          take: 10,
          select: {
            id: true, bookingCode: true, status: true,
            checkinDate: true, checkoutDate: true, totalPrice: true,
            room: { select: { id: true, name: true } },
          },
        },
      },
    });
  }

  async findRaw(id: string) {
    return this.prisma.customer.findUnique({ where: { id } });
  }

  async findByPhone(phone: string) {
    return this.prisma.customer.findUnique({ where: { phone } });
  }

  async create(data: Prisma.CustomerCreateInput) {
    return this.prisma.customer.create({ data });
  }

  async update(id: string, data: Prisma.CustomerUpdateInput) {
    return this.prisma.customer.update({ where: { id }, data });
  }

  async delete(id: string) {
    return this.prisma.customer.delete({ where: { id } });
  }

  async countActiveBookings(customerId: string) {
    return this.prisma.booking.count({
      where: { customerId, status: { in: ['HOLD', 'CONFIRMED', 'CHECKED_IN'] } },
    });
  }

  async getBookings(customerId: string) {
    return this.prisma.booking.findMany({
      where: { customerId },
      include: {
        room: { select: { id: true, name: true, property: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getLastStay(customerId: string) {
    return this.prisma.booking.findFirst({
      where: { customerId, status: 'CHECKED_OUT' },
      orderBy: { checkoutDate: 'desc' },
      select: { checkoutDate: true },
    });
  }

  async aggregateBookingStats(customerId: string) {
    return this.prisma.booking.aggregate({
      where: { customerId, status: 'CHECKED_OUT' },
      _count: true,
      _sum: { totalPrice: true },
    });
  }
}
