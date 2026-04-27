import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { UsersRepository } from './users.repository';
import { PropertiesRepository } from '../properties/properties.repository';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { Messages } from '../../i18n';
import * as bcrypt from 'bcryptjs';
import { Role } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(
    private repo: UsersRepository,
    private propertiesRepo: PropertiesRepository,
  ) {}

  async findAll(msg: Messages, currentUser: any, role?: Role) {
    const where: any = {};
    if (role) where.role = role;

    if (currentUser.role === Role.OWNER) {
      const propertyIds = await this.repo.getOwnedPropertyIds(currentUser.id);
      where.propertyId = { in: propertyIds };
    } else if (currentUser.role === Role.MANAGER) {
      where.propertyId = currentUser.propertyId;
    }

    const users = await this.repo.findAll(where);
    return { message: msg.users.listSuccess, data: users };
  }

  async findOne(id: string, msg: Messages) {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundException(msg.users.notFound);
    return { message: msg.users.getSuccess, data: user };
  }

  async create(dto: CreateUserDto, currentUser: any, msg: Messages) {
    const existing = await this.repo.findByEmail(dto.email);
    if (existing) throw new ConflictException(msg.users.emailDuplicate);

    if (dto.phone) {
      const phoneExist = await this.repo.findByPhone(dto.phone);
      if (phoneExist) throw new ConflictException(msg.users.phoneDuplicate);
    }

    if (dto.propertyId) {
      const property = await this.propertiesRepo.findRaw(dto.propertyId);
      if (!property) throw new NotFoundException(msg.properties.notFound);
      if (currentUser.role === Role.OWNER && property.ownerId !== currentUser.id) {
        throw new ForbiddenException(msg.users.forbidden);
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.repo.create({
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      passwordHash,
      role: dto.role,
      ...(dto.propertyId ? { property: { connect: { id: dto.propertyId } } } : {}),
    });

    return { message: msg.users.createSuccess, data: user };
  }

  async update(id: string, dto: UpdateUserDto, msg: Messages) {
    const userRaw = await this.repo.findById(id);
    if (!userRaw) throw new NotFoundException(msg.users.notFound);

    if (dto.email && dto.email !== userRaw.email) {
      const existing = await this.repo.findByEmail(dto.email);
      if (existing) throw new ConflictException(msg.users.emailDuplicate);
    }

    if (dto.phone) {
      const phoneExist = await this.repo.findPhoneDuplicate(dto.phone, id);
      if (phoneExist) throw new ConflictException(msg.users.phoneDuplicate);
    }

    const updated = await this.repo.update(id, dto);
    return { message: msg.users.updateSuccess, data: updated };
  }

  async updateRole(id: string, role: Role, msg: Messages) {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundException(msg.users.notFound);

    const updated = await this.repo.updateRole(id, role);
    return { message: msg.users.updateSuccess, data: updated };
  }

  async changePassword(userId: string, dto: ChangePasswordDto, msg: Messages) {
    const fullUser = await this.repo.findRawById(userId);
    if (!fullUser) throw new NotFoundException(msg.users.notFound);

    const isValid = await bcrypt.compare(dto.currentPassword, fullUser.passwordHash);
    if (!isValid) {
      throw new BadRequestException(msg.users.wrongPassword);
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await this.repo.update(userId, { passwordHash });

    return { message: msg.users.changePasswordSuccess, data: null };
  }

  async remove(id: string, currentUserId: string, msg: Messages) {
    if (id === currentUserId) {
      throw new BadRequestException(msg.users.cannotDeleteSelf);
    }
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundException(msg.users.notFound);

    await this.repo.softDelete(id);
    return { message: msg.users.disableSuccess, data: null };
  }
}
