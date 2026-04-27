import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { RoomsRepository } from './rooms.repository';
import { PropertiesRepository } from '../properties/properties.repository';
import { RoomTypesRepository } from '../room-types/room-types.repository';
import { CloudinaryService } from '../../config/cloudinary.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { Messages } from '../../i18n';
import { Role, RoomStatus } from '@prisma/client';

@Injectable()
export class RoomsService {
  constructor(
    private repo: RoomsRepository,
    private propertiesRepo: PropertiesRepository,
    private roomTypesRepo: RoomTypesRepository,
    private cloudinary: CloudinaryService,
  ) {}

  async findAll(
    user: any,
    msg: Messages,
    query: {
      propertyId?: string; status?: RoomStatus; roomTypeId?: string;
      floor?: number; minPrice?: number; maxPrice?: number;
      capacity?: number; page?: number; limit?: number; sort?: string;
    },
  ) {
    const where: any = { isActive: true };
    if (query.propertyId) where.propertyId = query.propertyId;
    if (query.status) where.status = query.status;
    if (query.roomTypeId) where.roomTypeId = query.roomTypeId;
    if (query.floor) where.floor = query.floor;
    if (query.capacity) where.capacity = { gte: query.capacity };
    if (query.minPrice || query.maxPrice) {
      where.pricePerNight = {};
      if (query.minPrice) where.pricePerNight.gte = query.minPrice;
      if (query.maxPrice) where.pricePerNight.lte = query.maxPrice;
    }

    if (user.role === Role.OWNER) {
      where.property = { ownerId: user.id };
    } else if ([Role.MANAGER, Role.SALE, Role.RECEPTIONIST].includes(user.role)) {
      where.propertyId = user.propertyId;
    }

    const orderBy: any = {};
    if (query.sort === 'price_asc') orderBy.pricePerNight = 'asc';
    else if (query.sort === 'price_desc') orderBy.pricePerNight = 'desc';
    else orderBy.createdAt = 'desc';

    const result = await this.repo.findAll(where, { page: query.page, limit: query.limit }, orderBy);
    return { message: msg.rooms.listSuccess, ...result };
  }

  async findOne(id: string, msg: Messages) {
    const room = await this.repo.findById(id);
    if (!room) throw new NotFoundException(msg.rooms.notFound);
    return { message: msg.rooms.getSuccess, data: room };
  }

  async create(dto: CreateRoomDto, user: any, msg: Messages) {
    const property = await this.propertiesRepo.findRaw(dto.propertyId);
    if (!property) throw new NotFoundException(msg.properties.notFound);
    if (user.role === Role.OWNER && property.ownerId !== user.id) {
      throw new ForbiddenException(msg.rooms.forbiddenAdd);
    }

    const roomType = await this.roomTypesRepo.findById(dto.roomTypeId);
    if (!roomType) throw new NotFoundException(msg.roomTypes.notFound);

    const { amenityIds, propertyId, roomTypeId, ...roomData } = dto;

    const room = await this.repo.create({
      ...roomData,
      property: { connect: { id: propertyId } },
      roomType: { connect: { id: roomTypeId } },
      ...(amenityIds?.length ? {
        amenities: { create: amenityIds.map((amenityId) => ({ amenity: { connect: { id: amenityId } } })) },
      } : {}),
    });

    return { message: msg.rooms.createSuccess, data: room };
  }

  async update(id: string, dto: UpdateRoomDto, user: any, msg: Messages) {
    await this.getRoomWithAccess(id, user, msg);
    const { amenityIds, roomTypeId, ...roomData } = dto;

    const updated = await this.repo.update(id, {
      ...roomData,
      ...(roomTypeId ? { roomType: { connect: { id: roomTypeId } } } : {}),
      ...(amenityIds !== undefined ? {
        amenities: {
          deleteMany: {},
          create: amenityIds.map((amenityId) => ({ amenity: { connect: { id: amenityId } } })),
        },
      } : {}),
    });

    return { message: msg.rooms.updateSuccess, data: updated };
  }

  async updateStatus(id: string, status: RoomStatus, user: any, msg: Messages) {
    await this.getRoomWithAccess(id, user, msg);
    const updated = await this.repo.updateStatus(id, status);
    return { message: msg.rooms.updateSuccess, data: updated };
  }

  async remove(id: string, user: any, msg: Messages) {
    await this.getRoomWithAccess(id, user, msg);

    const activeBookings = await this.repo.countActiveBookings(id);
    if (activeBookings > 0) {
      throw new ConflictException(msg.rooms.hasActiveBookings);
    }

    await this.repo.softDelete(id);
    return { message: msg.rooms.deleteSuccess, data: null };
  }

  async getBookings(id: string, msg: Messages, startDate?: string, endDate?: string) {
    const room = await this.repo.findRaw(id);
    if (!room) throw new NotFoundException(msg.rooms.notFound);

    const where: any = {};
    if (startDate) where.checkinDate = { gte: new Date(startDate) };
    if (endDate) where.checkoutDate = { ...where.checkoutDate, lte: new Date(endDate) };

    const bookings = await this.repo.findRoomBookings(id, where);
    return { message: msg.rooms.listSuccess, data: bookings };
  }

  async checkAvailability(id: string, checkinDate: string, checkoutDate: string, msg: Messages) {
    const room = await this.repo.findRaw(id);
    if (!room) throw new NotFoundException(msg.rooms.notFound);

    const conflicting = await this.repo.countConflictingBookings(id, new Date(checkinDate), new Date(checkoutDate));

    return {
      message: msg.rooms.getSuccess,
      data: { available: conflicting === 0, roomId: id, checkinDate, checkoutDate },
    };
  }

  async uploadImages(roomId: string, files: Express.Multer.File[], user: any, msg: Messages) {
    await this.getRoomWithAccess(roomId, user, msg);

    const currentCount = await this.repo.countImages(roomId);
    const maxImages = 20;
    if (currentCount + files.length > maxImages) {
      throw new ConflictException(msg.rooms.maxImages(maxImages));
    }

    const uploadedImages = await Promise.all(
      files.map(async (file, index) => {
        const result = await this.cloudinary.uploadImage(file, `halong24h/rooms/${roomId}`);
        return {
          roomId,
          url: result.secure_url,
          publicId: result.public_id,
          isCover: currentCount === 0 && index === 0,
          sortOrder: currentCount + index,
        };
      }),
    );

    const images = await this.repo.createImages(uploadedImages);
    return { message: msg.rooms.uploadSuccess(images.length), data: images };
  }

  async deleteImage(roomId: string, imageId: string, user: any, msg: Messages) {
    await this.getRoomWithAccess(roomId, user, msg);

    const image = await this.repo.findImage(imageId, roomId);
    if (!image) throw new NotFoundException(msg.rooms.imageNotFound);

    await this.cloudinary.deleteImage(image.publicId);
    await this.repo.deleteImage(imageId);

    if (image.isCover) {
      const firstImage = await this.repo.getFirstImage(roomId);
      if (firstImage) {
        await this.repo.setCoverImage(firstImage.id);
      }
    }

    return { message: msg.rooms.deleteImageSuccess, data: null };
  }

  async setCoverImage(roomId: string, imageId: string, user: any, msg: Messages) {
    await this.getRoomWithAccess(roomId, user, msg);
    await this.repo.resetCoverImages(roomId);
    const image = await this.repo.setCoverImage(imageId);
    return { message: msg.rooms.setCoverSuccess, data: image };
  }

  private async getRoomWithAccess(id: string, user: any, msg: Messages) {
    const room = await this.repo.findWithProperty(id);
    if (!room) throw new NotFoundException(msg.rooms.notFound);
    if (user.role === Role.OWNER && room.property.ownerId !== user.id) {
      throw new ForbiddenException(msg.rooms.forbidden);
    }
    return room;
  }
}
