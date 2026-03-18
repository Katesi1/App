import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { BookingsRepository } from './bookings.repository';
import { RoomsRepository } from '../rooms/rooms.repository';
import { CustomersService } from '../customers/customers.service';
import { RedisService } from '../../config/redis.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingDto } from './dto/update-booking.dto';
import { Messages } from '../../i18n';
import { BookingStatus, Role, RoomStatus } from '@prisma/client';

const HOLD_DURATION_SECONDS = 1800;

@Injectable()
export class BookingsService {
  constructor(
    private repo: BookingsRepository,
    private roomsRepo: RoomsRepository,
    private customersService: CustomersService,
    private redis: RedisService,
  ) {}

  async findAll(
    user: any,
    msg: Messages,
    query: {
      status?: BookingStatus; roomId?: string; customerId?: string;
      startDate?: string; endDate?: string; source?: string;
      page?: number; limit?: number;
    },
  ) {
    const where: any = {};
    if (query.status) where.status = query.status;
    if (query.roomId) where.roomId = query.roomId;
    if (query.customerId) where.customerId = query.customerId;
    if (query.source) where.source = query.source;
    if (query.startDate || query.endDate) {
      where.checkinDate = {};
      if (query.startDate) where.checkinDate.gte = new Date(query.startDate);
      if (query.endDate) where.checkinDate.lte = new Date(query.endDate);
    }

    if ([Role.SALE, Role.RECEPTIONIST, Role.MANAGER].includes(user.role)) {
      where.room = { propertyId: user.propertyId };
    } else if (user.role === Role.OWNER) {
      where.room = { property: { ownerId: user.id } };
    }

    const result = await this.repo.findAll(where, { page: query.page, limit: query.limit });

    const data = await Promise.all(
      result.data.map(async (booking) => {
        if (booking.status === BookingStatus.HOLD) {
          const ttl = await this.redis.getHoldTtl(booking.roomId);
          return { ...booking, holdRemainingSeconds: ttl > 0 ? ttl : 0 };
        }
        return booking;
      }),
    );

    return { message: msg.bookings.listSuccess, data, meta: result.meta };
  }

  async findOne(id: string, user: any, msg: Messages) {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);

    let holdRemainingSeconds = 0;
    if (booking.status === BookingStatus.HOLD) {
      const ttl = await this.redis.getHoldTtl(booking.roomId);
      holdRemainingSeconds = ttl > 0 ? ttl : 0;
    }

    return { message: msg.bookings.getSuccess, data: { ...booking, holdRemainingSeconds } };
  }

  async create(dto: CreateBookingDto, user: any, msg: Messages) {
    const checkin = new Date(dto.checkinDate);
    const checkout = new Date(dto.checkoutDate);
    if (checkin >= checkout) throw new BadRequestException(msg.bookings.checkoutBeforeCheckin);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (checkin < today) throw new BadRequestException(msg.bookings.checkinInPast);

    const room = await this.roomsRepo.findRaw(dto.roomId);
    if (!room || !room.isActive) throw new NotFoundException(msg.rooms.notFound);
    if (dto.guestCount > room.capacity) throw new BadRequestException(msg.bookings.exceedsCapacity);

    const conflict = await this.repo.findConflicting(dto.roomId, checkin, checkout);
    if (conflict) throw new ConflictException(msg.bookings.roomAlreadyBooked);

    const existingHold = await this.redis.getHold(dto.roomId);
    if (existingHold) {
      const holdBooking = await this.repo.findActiveHold(existingHold);
      if (holdBooking && holdBooking.createdBy !== user.id) {
        const ttl = await this.redis.getHoldTtl(dto.roomId);
        throw new ConflictException(msg.bookings.roomOnHold(Math.ceil(ttl / 60)));
      }
    }

    const customer = await this.customersService.findOrCreate(dto.customerName, dto.customerPhone);

    // Calculate price
    const nights = Math.ceil((checkout.getTime() - checkin.getTime()) / (1000 * 60 * 60 * 24));
    const pricePerNight = Number(room.pricePerNight);
    const weekendPrice = room.weekendPrice ? Number(room.weekendPrice) : pricePerNight;
    let totalPrice = 0;
    for (let i = 0; i < nights; i++) {
      const date = new Date(checkin);
      date.setDate(date.getDate() + i);
      const day = date.getDay();
      totalPrice += (day === 5 || day === 6) ? weekendPrice : pricePerNight;
    }
    totalPrice += (dto.extraCharges || 0) - (dto.discount || 0);

    const bookingCode = await this.generateBookingCode();

    await this.repo.cancelHoldsForRoom(dto.roomId);

    const holdExpireAt = new Date(Date.now() + HOLD_DURATION_SECONDS * 1000);

    const booking = await this.repo.create({
      bookingCode,
      room: { connect: { id: dto.roomId } },
      customer: { connect: { id: customer.id } },
      creator: { connect: { id: user.id } },
      checkinDate: checkin,
      checkoutDate: checkout,
      guestCount: dto.guestCount,
      status: BookingStatus.HOLD,
      totalPrice,
      extraCharges: dto.extraCharges || 0,
      discount: dto.discount || 0,
      deposit: dto.deposit || 0,
      source: dto.source || 'DIRECT',
      notes: dto.notes,
      holdExpireAt,
    });

    await this.redis.setHold(dto.roomId, booking.id, HOLD_DURATION_SECONDS);
    await this.roomsRepo.updateStatus(dto.roomId, RoomStatus.BOOKED);

    return { message: msg.bookings.holdSuccess, data: { ...booking, holdRemainingSeconds: HOLD_DURATION_SECONDS } };
  }

  async updateStatus(id: string, status: BookingStatus, user: any, msg: Messages, cancelReason?: string) {
    const booking = await this.repo.findRawWithRoom(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);

    const validTransitions: Record<string, BookingStatus[]> = {
      HOLD: [BookingStatus.CONFIRMED, BookingStatus.CANCELLED],
      CONFIRMED: [BookingStatus.CHECKED_IN, BookingStatus.CANCELLED],
      CHECKED_IN: [BookingStatus.CHECKED_OUT],
      CHECKED_OUT: [],
      CANCELLED: [],
    };

    if (!validTransitions[booking.status]?.includes(status)) {
      throw new BadRequestException(msg.bookings.invalidStatusTransition);
    }

    const updated = await this.repo.update(id, {
      status,
      holdExpireAt: status === BookingStatus.CONFIRMED ? null : undefined,
      cancelReason: status === BookingStatus.CANCELLED ? cancelReason : undefined,
    });

    if (status === BookingStatus.CONFIRMED || status === BookingStatus.CANCELLED) {
      await this.redis.delHold(booking.roomId);
    }
    if (status === BookingStatus.CANCELLED) {
      await this.updateRoomStatusAfterCancel(booking.roomId);
    }

    return { message: msg.bookings.updateSuccess, data: updated };
  }

  async checkin(id: string, user: any, msg: Messages) {
    const booking = await this.repo.findRaw(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);
    if (booking.status !== BookingStatus.CONFIRMED) {
      throw new BadRequestException(msg.bookings.onlyCheckinConfirmed);
    }

    const updated = await this.repo.update(id, { status: BookingStatus.CHECKED_IN, actualCheckin: new Date() });
    await this.roomsRepo.updateStatus(booking.roomId, RoomStatus.OCCUPIED);

    return { message: msg.bookings.checkinSuccess, data: updated };
  }

  async checkout(id: string, user: any, msg: Messages) {
    const booking = await this.repo.findRaw(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);
    if (booking.status !== BookingStatus.CHECKED_IN) {
      throw new BadRequestException(msg.bookings.onlyCheckoutCheckedIn);
    }

    const updated = await this.repo.update(id, { status: BookingStatus.CHECKED_OUT, actualCheckout: new Date() });
    await this.roomsRepo.updateStatus(booking.roomId, RoomStatus.VACANT);
    await this.customersService.updateCustomerStats(booking.customerId);

    return { message: msg.bookings.checkoutSuccess, data: updated };
  }

  async cancel(id: string, user: any, msg: Messages, cancelReason?: string) {
    const booking = await this.repo.findRaw(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);
    if (booking.status === BookingStatus.CANCELLED) throw new BadRequestException(msg.bookings.alreadyCancelled);
    if (booking.status === BookingStatus.CHECKED_OUT) throw new BadRequestException(msg.bookings.cannotCancelCompleted);

    await this.repo.update(id, { status: BookingStatus.CANCELLED, cancelReason });
    await this.redis.delHold(booking.roomId);
    await this.updateRoomStatusAfterCancel(booking.roomId);

    return { message: msg.bookings.cancelSuccess, data: null };
  }

  async update(id: string, dto: UpdateBookingDto, user: any, msg: Messages) {
    const booking = await this.repo.findRaw(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);

    if ([BookingStatus.CHECKED_OUT, BookingStatus.CANCELLED].includes(booking.status as any)) {
      throw new BadRequestException(msg.bookings.cannotUpdateCompleted);
    }

    const data: any = { ...dto };
    if (dto.checkinDate) data.checkinDate = new Date(dto.checkinDate);
    if (dto.checkoutDate) data.checkoutDate = new Date(dto.checkoutDate);

    if (dto.checkinDate || dto.checkoutDate || dto.extraCharges !== undefined || dto.discount !== undefined) {
      const checkin = dto.checkinDate ? new Date(dto.checkinDate) : booking.checkinDate;
      const checkout = dto.checkoutDate ? new Date(dto.checkoutDate) : booking.checkoutDate;
      const room = await this.roomsRepo.findRaw(booking.roomId);
      if (room) {
        const nights = Math.ceil((checkout.getTime() - checkin.getTime()) / (1000 * 60 * 60 * 24));
        const pricePerNight = Number(room.pricePerNight);
        const weekendPrice = room.weekendPrice ? Number(room.weekendPrice) : pricePerNight;
        let totalPrice = 0;
        for (let i = 0; i < nights; i++) {
          const d = new Date(checkin);
          d.setDate(d.getDate() + i);
          totalPrice += (d.getDay() === 5 || d.getDay() === 6) ? weekendPrice : pricePerNight;
        }
        data.totalPrice = totalPrice + (dto.extraCharges ?? Number(booking.extraCharges)) - (dto.discount ?? Number(booking.discount));
      }
    }

    const updated = await this.repo.update(id, data);
    return { message: msg.bookings.updateSuccess, data: updated };
  }

  async remove(id: string, user: any, msg: Messages) {
    const booking = await this.repo.findRaw(id);
    if (!booking) throw new NotFoundException(msg.bookings.notFound);
    if (booking.status !== BookingStatus.HOLD) throw new BadRequestException(msg.bookings.onlyDeleteHold);

    await this.repo.delete(id);
    await this.redis.delHold(booking.roomId);
    await this.updateRoomStatusAfterCancel(booking.roomId);

    return { message: msg.bookings.deleteSuccess, data: null };
  }

  async expireHoldBookings() {
    const expired = await this.repo.findExpiredHolds();
    if (expired.length > 0) {
      await this.repo.cancelExpiredHolds(expired.map((b) => b.id));
      await Promise.all(expired.map(async (b) => {
        await this.redis.delHold(b.roomId);
        await this.updateRoomStatusAfterCancel(b.roomId);
      }));
    }
    return expired.length;
  }

  private async generateBookingCode(): Promise<string> {
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const count = await this.repo.countTodayBookings();
    return `HL-${dateStr}-${String(count + 1).padStart(4, '0')}`;
  }

  private async updateRoomStatusAfterCancel(roomId: string) {
    const active = await this.repo.countActiveForRoom(roomId);
    if (active === 0) {
      await this.roomsRepo.updateStatus(roomId, RoomStatus.VACANT);
    }
  }
}
