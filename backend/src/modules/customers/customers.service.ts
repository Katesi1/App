import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { CustomersRepository } from './customers.repository';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { Messages } from '../../i18n';
import { Decimal } from '@prisma/client/runtime/library';

const VIP_BOOKING_THRESHOLD = 5;
const VIP_SPENT_THRESHOLD = 10_000_000;

@Injectable()
export class CustomersService {
  constructor(private repo: CustomersRepository) {}

  async findAll(msg: Messages, query: { isVip?: boolean; search?: string; page?: number; limit?: number; sort?: string }) {
    const where: any = {};
    if (query.isVip !== undefined) where.isVip = query.isVip;
    if (query.search) {
      where.OR = [
        { fullName: { contains: query.search, mode: 'insensitive' } },
        { phone: { contains: query.search } },
      ];
    }

    const orderBy: any = query.sort === 'total_spent' ? { totalSpent: 'desc' } : { createdAt: 'desc' };

    const result = await this.repo.findAll(where, { page: query.page, limit: query.limit }, orderBy);
    return { message: msg.customers.listSuccess, ...result };
  }

  async findOne(id: string, msg: Messages) {
    const customer = await this.repo.findById(id);
    if (!customer) throw new NotFoundException(msg.customers.notFound);
    return { message: msg.customers.getSuccess, data: customer };
  }

  async create(dto: CreateCustomerDto, msg: Messages) {
    const existing = await this.repo.findByPhone(dto.phone);
    if (existing) throw new ConflictException(msg.customers.phoneDuplicate);

    const customer = await this.repo.create({
      ...dto,
      dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
    });
    return { message: msg.customers.createSuccess, data: customer };
  }

  async update(id: string, dto: UpdateCustomerDto, msg: Messages) {
    const customer = await this.repo.findRaw(id);
    if (!customer) throw new NotFoundException(msg.customers.notFound);

    if (dto.phone && dto.phone !== customer.phone) {
      const existing = await this.repo.findByPhone(dto.phone);
      if (existing) throw new ConflictException(msg.customers.phoneDuplicate);
    }

    const updated = await this.repo.update(id, {
      ...dto,
      dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : undefined,
    });
    return { message: msg.customers.updateSuccess, data: updated };
  }

  async remove(id: string, msg: Messages) {
    const customer = await this.repo.findRaw(id);
    if (!customer) throw new NotFoundException(msg.customers.notFound);

    const activeBookings = await this.repo.countActiveBookings(id);
    if (activeBookings > 0) {
      throw new ConflictException(msg.customers.hasActiveBookings);
    }

    await this.repo.delete(id);
    return { message: msg.customers.deleteSuccess, data: null };
  }

  async getBookings(id: string, msg: Messages) {
    const customer = await this.repo.findRaw(id);
    if (!customer) throw new NotFoundException(msg.customers.notFound);

    const bookings = await this.repo.getBookings(id);
    return { message: msg.customers.listSuccess, data: bookings };
  }

  async getStats(id: string, msg: Messages) {
    const customer = await this.repo.findRaw(id);
    if (!customer) throw new NotFoundException(msg.customers.notFound);

    const lastBooking = await this.repo.getLastStay(id);

    return {
      message: msg.customers.getSuccess,
      data: {
        totalBookings: customer.totalBookings,
        totalSpent: customer.totalSpent,
        isVip: customer.isVip,
        lastStay: lastBooking?.checkoutDate || null,
      },
    };
  }

  async updateCustomerStats(customerId: string) {
    const stats = await this.repo.aggregateBookingStats(customerId);

    const totalBookings = stats._count;
    const totalSpent = stats._sum.totalPrice || new Decimal(0);
    const shouldBeVip =
      totalBookings >= VIP_BOOKING_THRESHOLD ||
      totalSpent.greaterThanOrEqualTo(VIP_SPENT_THRESHOLD);

    const customer = await this.repo.findRaw(customerId);

    await this.repo.update(customerId, {
      totalBookings,
      totalSpent,
      isVip: shouldBeVip,
      vipSince: shouldBeVip && !customer?.isVip ? new Date() : undefined,
    });
  }

  async findOrCreate(fullName: string, phone: string) {
    let customer = await this.repo.findByPhone(phone);
    if (!customer) {
      customer = await this.repo.create({ fullName, phone });
    }
    return customer;
  }
}
