import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository } from '../../common/repositories/base.repository';
import { Prisma } from '@prisma/client';

@Injectable()
export class RoomTypesRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll() {
    return this.prisma.roomType.findMany({
      orderBy: { name: 'asc' },
      include: { _count: { select: { rooms: true } } },
    });
  }

  async findById(id: string) {
    return this.prisma.roomType.findUnique({
      where: { id },
      include: { _count: { select: { rooms: true } } },
    });
  }

  async findByName(name: string) {
    return this.prisma.roomType.findUnique({ where: { name } });
  }

  async create(data: Prisma.RoomTypeCreateInput) {
    return this.prisma.roomType.create({ data });
  }

  async update(id: string, data: Prisma.RoomTypeUpdateInput) {
    return this.prisma.roomType.update({ where: { id }, data });
  }

  async delete(id: string) {
    return this.prisma.roomType.delete({ where: { id } });
  }

  async countRooms(roomTypeId: string) {
    return this.prisma.room.count({ where: { roomTypeId } });
  }
}
