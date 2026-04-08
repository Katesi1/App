import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository } from '../../common/repositories/base.repository';
import { Prisma } from '@prisma/client';

@Injectable()
export class AmenitiesRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where?: Prisma.AmenityWhereInput) {
    return this.prisma.amenity.findMany({
      where,
      orderBy: { name: 'asc' },
    });
  }

  async findById(id: string) {
    return this.prisma.amenity.findUnique({ where: { id } });
  }

  async findByName(name: string) {
    return this.prisma.amenity.findUnique({ where: { name } });
  }

  async create(data: Prisma.AmenityCreateInput) {
    return this.prisma.amenity.create({ data });
  }

  async update(id: string, data: Prisma.AmenityUpdateInput) {
    return this.prisma.amenity.update({ where: { id }, data });
  }

  async delete(id: string) {
    return this.prisma.amenity.delete({ where: { id } });
  }
}
