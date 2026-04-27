import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { RoomTypesRepository } from './room-types.repository';
import { CreateRoomTypeDto } from './dto/create-room-type.dto';
import { UpdateRoomTypeDto } from './dto/update-room-type.dto';
import { Messages } from '../../i18n';

@Injectable()
export class RoomTypesService {
  constructor(private repo: RoomTypesRepository) {}

  async findAll(msg: Messages) {
    const roomTypes = await this.repo.findAll();
    return { message: msg.roomTypes.listSuccess, data: roomTypes };
  }

  async findOne(id: string, msg: Messages) {
    const roomType = await this.repo.findById(id);
    if (!roomType) throw new NotFoundException(msg.roomTypes.notFound);
    return { message: msg.roomTypes.getSuccess, data: roomType };
  }

  async create(dto: CreateRoomTypeDto, msg: Messages) {
    const existing = await this.repo.findByName(dto.name);
    if (existing) throw new ConflictException(msg.roomTypes.nameDuplicate);

    const roomType = await this.repo.create(dto);
    return { message: msg.roomTypes.createSuccess, data: roomType };
  }

  async update(id: string, dto: UpdateRoomTypeDto, msg: Messages) {
    const roomType = await this.repo.findById(id);
    if (!roomType) throw new NotFoundException(msg.roomTypes.notFound);

    if (dto.name && dto.name !== roomType.name) {
      const existing = await this.repo.findByName(dto.name);
      if (existing) throw new ConflictException(msg.roomTypes.nameDuplicate);
    }

    const updated = await this.repo.update(id, dto);
    return { message: msg.roomTypes.updateSuccess, data: updated };
  }

  async remove(id: string, msg: Messages) {
    const roomType = await this.repo.findById(id);
    if (!roomType) throw new NotFoundException(msg.roomTypes.notFound);

    const roomCount = await this.repo.countRooms(id);
    if (roomCount > 0) {
      throw new ConflictException(msg.roomTypes.hasRooms);
    }

    await this.repo.delete(id);
    return { message: msg.roomTypes.deleteSuccess, data: null };
  }
}
