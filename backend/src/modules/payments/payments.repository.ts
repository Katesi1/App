import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository, PaginationParams } from '../../common/repositories/base.repository';
import { Prisma } from '@prisma/client';

@Injectable()
export class PaymentsRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where: Prisma.PaymentWhereInput, pagination?: PaginationParams) {
    const { skip, take, page, limit } = this.paginate(pagination);

    const [payments, total] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        include: {
          booking: { select: { id: true, bookingCode: true } },
          creator: { select: { id: true, fullName: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
      this.prisma.payment.count({ where }),
    ]);

    return { data: payments, meta: { page, limit, total } };
  }

  async findById(id: string) {
    return this.prisma.payment.findUnique({
      where: { id },
      include: {
        booking: {
          select: {
            id: true, bookingCode: true, totalPrice: true,
            customer: { select: { fullName: true, phone: true } },
          },
        },
        creator: { select: { id: true, fullName: true } },
      },
    });
  }

  async findRaw(id: string) {
    return this.prisma.payment.findUnique({ where: { id } });
  }

  async create(data: Prisma.PaymentCreateInput) {
    return this.prisma.payment.create({
      data,
      include: {
        booking: { select: { id: true, bookingCode: true } },
      },
    });
  }

  async update(id: string, data: Prisma.PaymentUpdateInput) {
    return this.prisma.payment.update({ where: { id }, data });
  }

  async sumDepositForBooking(bookingId: string) {
    const result = await this.prisma.payment.aggregate({
      where: { bookingId, type: 'DEPOSIT', status: 'COMPLETED' },
      _sum: { amount: true },
    });
    return result._sum.amount || 0;
  }
}
