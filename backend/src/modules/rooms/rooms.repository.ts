import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository, PaginationParams } from '../../common/repositories/base.repository';
import { Prisma, RoomStatus } from '@prisma/client';

@Injectable()
export class RoomsRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where: Prisma.RoomWhereInput, pagination?: PaginationParams, orderBy?: Prisma.RoomOrderByWithRelationInput) {
    const { skip, take, page, limit } = this.paginate(pagination);

    const [rooms, total] = await Promise.all([
      this.prisma.room.findMany({
        where,
        include: {
          property: { select: { id: true, name: true } },
          roomType: { select: { id: true, name: true } },
          images: { where: { isCover: true }, take: 1 },
          _count: { select: { bookings: true } },
        },
        orderBy: orderBy || { createdAt: 'desc' },
        skip,
        take,
      }),
      this.prisma.room.count({ where }),
    ]);

    return { data: rooms, meta: { page, limit, total } };
  }

  async findById(id: string) {
    return this.prisma.room.findUnique({
      where: { id },
      include: {
        property: {
          select: {
            id: true, name: true, address: true, city: true,
            owner: { select: { id: true, fullName: true, phone: true } },
          },
        },
        roomType: true,
        images: { orderBy: { sortOrder: 'asc' } },
        amenities: { include: { amenity: true } },
      },
    });
  }

  async findRaw(id: string) {
    return this.prisma.room.findUnique({ where: { id } });
  }

  async findWithProperty(id: string) {
    return this.prisma.room.findUnique({
      where: { id },
      include: { property: { select: { ownerId: true } } },
    });
  }

  async create(data: Prisma.RoomCreateInput) {
    return this.prisma.room.create({
      data,
      include: {
        property: { select: { id: true, name: true } },
        roomType: { select: { id: true, name: true } },
      },
    });
  }

  async update(id: string, data: Prisma.RoomUpdateInput) {
    return this.prisma.room.update({
      where: { id },
      data,
      include: {
        roomType: { select: { id: true, name: true } },
        amenities: { include: { amenity: true } },
      },
    });
  }

  async updateStatus(id: string, status: RoomStatus) {
    return this.prisma.room.update({
      where: { id },
      data: { status },
      select: { id: true, name: true, status: true },
    });
  }

  async softDelete(id: string) {
    return this.prisma.room.update({
      where: { id },
      data: { isActive: false, status: 'INACTIVE' },
    });
  }

  async countActiveBookings(roomId: string) {
    return this.prisma.booking.count({
      where: {
        roomId,
        status: { in: ['HOLD', 'CONFIRMED', 'CHECKED_IN'] },
      },
    });
  }

  // ─── Images ──────────────────────────────────────────────────────────────────

  async countImages(roomId: string) {
    return this.prisma.roomImage.count({ where: { roomId } });
  }

  async createImages(images: Prisma.RoomImageCreateManyInput[]) {
    return this.prisma.$transaction(
      images.map((img) => this.prisma.roomImage.create({ data: img })),
    );
  }

  async findImage(imageId: string, roomId: string) {
    return this.prisma.roomImage.findFirst({ where: { id: imageId, roomId } });
  }

  async deleteImage(imageId: string) {
    return this.prisma.roomImage.delete({ where: { id: imageId } });
  }

  async getFirstImage(roomId: string) {
    return this.prisma.roomImage.findFirst({
      where: { roomId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async resetCoverImages(roomId: string) {
    return this.prisma.roomImage.updateMany({
      where: { roomId },
      data: { isCover: false },
    });
  }

  async setCoverImage(imageId: string) {
    return this.prisma.roomImage.update({
      where: { id: imageId },
      data: { isCover: true },
    });
  }

  // ─── Bookings (for room context) ────────────────────────────────────────────

  async findRoomBookings(roomId: string, where?: Prisma.BookingWhereInput) {
    return this.prisma.booking.findMany({
      where: { roomId, ...where },
      include: {
        customer: { select: { id: true, fullName: true, phone: true } },
      },
      orderBy: { checkinDate: 'desc' },
    });
  }

  async countConflictingBookings(roomId: string, checkinDate: Date, checkoutDate: Date) {
    return this.prisma.booking.count({
      where: {
        roomId,
        status: { in: ['CONFIRMED', 'CHECKED_IN'] },
        checkinDate: { lt: checkoutDate },
        checkoutDate: { gt: checkinDate },
      },
    });
  }
}
