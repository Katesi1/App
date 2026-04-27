import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PropertiesRepository } from './properties.repository';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { Messages } from '../../i18n';
import { Role } from '@prisma/client';

@Injectable()
export class PropertiesService {
  constructor(private repo: PropertiesRepository) {}

  async findAll(msg: Messages, currentUser: any) {
    const where: any = { isActive: true };

    if (currentUser.role === Role.OWNER) {
      where.ownerId = currentUser.id;
    } else if ([Role.MANAGER, Role.SALE, Role.RECEPTIONIST].includes(currentUser.role)) {
      where.id = currentUser.propertyId;
    }

    const properties = await this.repo.findAll(where);
    return { message: msg.properties.listSuccess, data: properties };
  }

  async findOne(id: string, currentUser: any, msg: Messages) {
    const property = await this.repo.findById(id);
    if (!property) throw new NotFoundException(msg.properties.notFound);
    this.checkAccess(property.ownerId, currentUser, msg);
    return { message: msg.properties.getSuccess, data: property };
  }

  async getStats(id: string, currentUser: any, msg: Messages) {
    const property = await this.repo.findRaw(id);
    if (!property) throw new NotFoundException(msg.properties.notFound);
    this.checkAccess(property.ownerId, currentUser, msg);

    const rooms = await this.repo.getActiveRooms(id);
    const totalRooms = rooms.length;
    const roomsByStatus = {
      vacant: rooms.filter((r) => r.status === 'VACANT').length,
      booked: rooms.filter((r) => r.status === 'BOOKED').length,
      occupied: rooms.filter((r) => r.status === 'OCCUPIED').length,
      maintenance: rooms.filter((r) => r.status === 'MAINTENANCE').length,
    };
    const occupancyRate = totalRooms > 0
      ? ((roomsByStatus.booked + roomsByStatus.occupied) / totalRooms) * 100
      : 0;

    return {
      message: msg.properties.statsSuccess,
      data: { totalRooms, roomsByStatus, occupancyRate: Math.round(occupancyRate * 100) / 100 },
    };
  }

  async create(dto: CreatePropertyDto, currentUser: any, msg: Messages) {
    const property = await this.repo.create({
      ...dto,
      owner: { connect: { id: currentUser.id } },
    });
    return { message: msg.properties.createSuccess, data: property };
  }

  async update(id: string, dto: UpdatePropertyDto, currentUser: any, msg: Messages) {
    const property = await this.repo.findRaw(id);
    if (!property) throw new NotFoundException(msg.properties.notFound);
    this.checkOwnership(property.ownerId, currentUser, msg);

    const updated = await this.repo.update(id, dto);
    return { message: msg.properties.updateSuccess, data: updated };
  }

  async remove(id: string, currentUser: any, msg: Messages) {
    const property = await this.repo.findRaw(id);
    if (!property) throw new NotFoundException(msg.properties.notFound);
    this.checkOwnership(property.ownerId, currentUser, msg);

    await this.repo.softDelete(id);
    return { message: msg.properties.deleteSuccess, data: null };
  }

  private checkAccess(ownerId: string, currentUser: any, msg: Messages) {
    if (currentUser.role === Role.OWNER && ownerId !== currentUser.id) {
      throw new ForbiddenException(msg.properties.forbidden);
    }
  }

  private checkOwnership(ownerId: string, currentUser: any, msg: Messages) {
    if (currentUser.role === Role.OWNER && ownerId !== currentUser.id) {
      throw new ForbiddenException(msg.properties.forbidden);
    }
  }
}
