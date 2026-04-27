import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository } from '../../common/repositories/base.repository';
import { Prisma } from '@prisma/client';

@Injectable()
export class PropertiesRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where?: Prisma.PropertyWhereInput) {
    return this.prisma.property.findMany({
      where,
      select: {
        id: true, name: true, address: true, city: true, phone: true,
        type: true, isActive: true, createdAt: true,
        _count: { select: { rooms: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.property.findUnique({
      where: { id },
      select: {
        id: true, name: true, address: true, city: true, phone: true,
        email: true, type: true, description: true, logoUrl: true,
        ownerId: true, isActive: true, createdAt: true,
        owner: { select: { id: true, fullName: true, email: true } },
        rooms: {
          where: { isActive: true },
          select: { id: true, name: true, status: true, pricePerNight: true },
        },
        _count: { select: { rooms: true, users: true } },
      },
    });
  }

  async findRaw(id: string) {
    return this.prisma.property.findUnique({ where: { id } });
  }

  async create(data: Prisma.PropertyCreateInput) {
    return this.prisma.property.create({
      data,
      select: {
        id: true, name: true, address: true, city: true,
        type: true, ownerId: true, createdAt: true,
      },
    });
  }

  async update(id: string, data: Prisma.PropertyUpdateInput) {
    return this.prisma.property.update({
      where: { id },
      data,
      select: {
        id: true, name: true, address: true, city: true,
        type: true, isActive: true, updatedAt: true,
      },
    });
  }

  async softDelete(id: string) {
    return this.prisma.property.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getActiveRooms(propertyId: string) {
    return this.prisma.room.findMany({
      where: { propertyId, isActive: true },
      select: { id: true, status: true, pricePerNight: true },
    });
  }
}
