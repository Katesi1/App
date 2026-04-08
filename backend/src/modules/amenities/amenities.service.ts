import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { AmenitiesRepository } from './amenities.repository';
import { CreateAmenityDto } from './dto/create-amenity.dto';
import { UpdateAmenityDto } from './dto/update-amenity.dto';
import { Messages } from '../../i18n';

@Injectable()
export class AmenitiesService {
  constructor(private repo: AmenitiesRepository) {}

  async findAll(msg: Messages, category?: string) {
    const where = category ? { category } : {};
    const amenities = await this.repo.findAll(where);
    return { message: msg.amenities.listSuccess, data: amenities };
  }

  async create(dto: CreateAmenityDto, msg: Messages) {
    const existing = await this.repo.findByName(dto.name);
    if (existing) throw new ConflictException(msg.amenities.nameDuplicate);

    const amenity = await this.repo.create(dto);
    return { message: msg.amenities.createSuccess, data: amenity };
  }

  async update(id: string, dto: UpdateAmenityDto, msg: Messages) {
    const amenity = await this.repo.findById(id);
    if (!amenity) throw new NotFoundException(msg.amenities.notFound);

    if (dto.name && dto.name !== amenity.name) {
      const existing = await this.repo.findByName(dto.name);
      if (existing) throw new ConflictException(msg.amenities.nameDuplicate);
    }

    const updated = await this.repo.update(id, dto);
    return { message: msg.amenities.updateSuccess, data: updated };
  }

  async remove(id: string, msg: Messages) {
    const amenity = await this.repo.findById(id);
    if (!amenity) throw new NotFoundException(msg.amenities.notFound);

    await this.repo.delete(id);
    return { message: msg.amenities.deleteSuccess, data: null };
  }
}
