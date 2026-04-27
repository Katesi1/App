import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PaymentsRepository } from './payments.repository';
import { BookingsRepository } from '../bookings/bookings.repository';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { Messages } from '../../i18n';
import { PaymentStatus } from '@prisma/client';

@Injectable()
export class PaymentsService {
  constructor(
    private repo: PaymentsRepository,
    private bookingsRepo: BookingsRepository,
  ) {}

  async findAll(
    msg: Messages,
    query: {
      bookingId?: string; method?: string; status?: PaymentStatus;
      startDate?: string; endDate?: string; page?: number; limit?: number;
    },
  ) {
    const where: any = {};
    if (query.bookingId) where.bookingId = query.bookingId;
    if (query.method) where.method = query.method;
    if (query.status) where.status = query.status;
    if (query.startDate || query.endDate) {
      where.createdAt = {};
      if (query.startDate) where.createdAt.gte = new Date(query.startDate);
      if (query.endDate) where.createdAt.lte = new Date(query.endDate);
    }

    const result = await this.repo.findAll(where, { page: query.page, limit: query.limit });
    return { message: msg.payments.listSuccess, ...result };
  }

  async findOne(id: string, msg: Messages) {
    const payment = await this.repo.findById(id);
    if (!payment) throw new NotFoundException(msg.payments.notFound);
    return { message: msg.payments.getSuccess, data: payment };
  }

  async create(dto: CreatePaymentDto, userId: string, msg: Messages) {
    const booking = await this.bookingsRepo.findRaw(dto.bookingId);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);

    const payment = await this.repo.create({
      booking: { connect: { id: dto.bookingId } },
      amount: dto.amount,
      method: dto.method,
      type: dto.type,
      transactionRef: dto.transactionRef,
      note: dto.note,
      creator: { connect: { id: userId } },
    });

    if (dto.type === 'DEPOSIT') {
      const totalDeposit = await this.repo.sumDepositForBooking(dto.bookingId);
      await this.bookingsRepo.update(dto.bookingId, { deposit: totalDeposit });
    }

    return { message: msg.payments.createSuccess, data: payment };
  }

  async updateStatus(id: string, status: PaymentStatus, msg: Messages) {
    const payment = await this.repo.findRaw(id);
    if (!payment) throw new NotFoundException(msg.payments.notFound);

    const updated = await this.repo.update(id, { status });
    return { message: msg.payments.updateSuccess, data: updated };
  }

  async createForBooking(bookingId: string, dto: CreatePaymentDto, userId: string, msg: Messages) {
    dto.bookingId = bookingId;
    return this.create(dto, userId, msg);
  }
}
