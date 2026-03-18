import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { BaseRepository } from '../../common/repositories/base.repository';
import { Prisma, Role } from '@prisma/client';

const USER_SELECT = {
  id: true,
  fullName: true,
  email: true,
  phone: true,
  role: true,
  propertyId: true,
  avatarUrl: true,
  isActive: true,
  lastLoginAt: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

@Injectable()
export class UsersRepository extends BaseRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findAll(where?: Prisma.UserWhereInput) {
    return this.prisma.user.findMany({
      where,
      select: USER_SELECT,
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      select: {
        ...USER_SELECT,
        property: {
          select: { id: true, name: true, address: true },
        },
      },
    });
  }

  async findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async findByPhone(phone: string) {
    return this.prisma.user.findFirst({ where: { phone } });
  }

  async findRawById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findByIdentifier(identifier: string) {
    return this.prisma.user.findFirst({
      where: {
        OR: [{ email: identifier }, { phone: identifier }],
        isActive: true,
      },
    });
  }

  async findPhoneDuplicate(phone: string, excludeId?: string) {
    return this.prisma.user.findFirst({
      where: { phone, ...(excludeId ? { NOT: { id: excludeId } } : {}) },
    });
  }

  async create(data: Prisma.UserCreateInput) {
    return this.prisma.user.create({
      data,
      select: {
        id: true, fullName: true, email: true, phone: true,
        role: true, propertyId: true, createdAt: true,
      },
    });
  }

  async update(id: string, data: Prisma.UserUpdateInput) {
    return this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true, fullName: true, email: true, phone: true,
        role: true, propertyId: true, avatarUrl: true,
        isActive: true, updatedAt: true,
      },
    });
  }

  async updateRole(id: string, role: Role) {
    return this.prisma.user.update({
      where: { id },
      data: { role },
      select: { id: true, fullName: true, role: true },
    });
  }

  async softDelete(id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getOwnedPropertyIds(ownerId: string): Promise<string[]> {
    const properties = await this.prisma.property.findMany({
      where: { ownerId },
      select: { id: true },
    });
    return properties.map((p) => p.id);
  }
}
