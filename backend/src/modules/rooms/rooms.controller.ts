import {
  Controller, Get, Post, Put, Patch, Delete,
  Body, Param, Query, UseGuards, UseInterceptors,
  UploadedFiles,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role, RoomStatus } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Rooms')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('rooms')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RoomsController {
  constructor(private roomsService: RoomsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach phong, ho tro filter' })
  @ApiQuery({ name: 'property_id', required: false })
  @ApiQuery({ name: 'status', enum: RoomStatus, required: false })
  @ApiQuery({ name: 'room_type_id', required: false })
  @ApiQuery({ name: 'floor', required: false, type: Number })
  @ApiQuery({ name: 'min_price', required: false, type: Number })
  @ApiQuery({ name: 'max_price', required: false, type: Number })
  @ApiQuery({ name: 'capacity', required: false, type: Number })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'sort', required: false, enum: ['price_asc', 'price_desc', 'newest'] })
  findAll(
    @CurrentUser() user: any,
    @Query('property_id') propertyId: string,
    @Query('status') status: RoomStatus,
    @Query('room_type_id') roomTypeId: string,
    @Query('floor') floor: number,
    @Query('min_price') minPrice: number,
    @Query('max_price') maxPrice: number,
    @Query('capacity') capacity: number,
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Query('sort') sort: string,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.findAll(user, msg, {
      propertyId, status, roomTypeId, floor, minPrice, maxPrice, capacity, page, limit, sort,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiet phong kem tien nghi, anh' })
  findOne(@Param('id') id: string, @Lang() msg: Messages) {
    return this.roomsService.findOne(id, msg);
  }

  @Get(':id/bookings')
  @ApiOperation({ summary: 'Lich su booking cua phong' })
  @ApiQuery({ name: 'start_date', required: false })
  @ApiQuery({ name: 'end_date', required: false })
  getBookings(
    @Param('id') id: string,
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.getBookings(id, msg, startDate, endDate);
  }

  @Get(':id/availability')
  @ApiOperation({ summary: 'Kiem tra phong trong theo khoang ngay' })
  @ApiQuery({ name: 'check_in', required: true })
  @ApiQuery({ name: 'check_out', required: true })
  checkAvailability(
    @Param('id') id: string,
    @Query('check_in') checkIn: string,
    @Query('check_out') checkOut: string,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.checkAvailability(id, checkIn, checkOut, msg);
  }

  @Post()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Tao phong moi' })
  create(@Body() dto: CreateRoomDto, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.roomsService.create(dto, user, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat phong' })
  update(@Param('id') id: string, @Body() dto: UpdateRoomDto, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.roomsService.update(id, dto, user, msg);
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Cap nhat trang thai phong' })
  updateStatus(
    @Param('id') id: string,
    @Body('status') status: RoomStatus,
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.updateStatus(id, status, user, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Xoa phong (soft delete)' })
  remove(@Param('id') id: string, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.roomsService.remove(id, user, msg);
  }

  @Post(':id/images')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Upload anh phong (max 10 anh/lan, JPG/PNG/WEBP)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { images: { type: 'array', items: { type: 'string', format: 'binary' } } } } })
  @UseInterceptors(
    FilesInterceptor('images', 10, {
      storage: memoryStorage(),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^image\/(jpeg|png|webp)$/)) {
          return cb(new Error('Chi chap nhan file anh JPG, PNG, WEBP'), false);
        }
        cb(null, true);
      },
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  uploadImages(
    @Param('id') roomId: string,
    @UploadedFiles() files: Express.Multer.File[],
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.uploadImages(roomId, files, user, msg);
  }

  @Delete(':id/images/:imgId')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xoa anh phong' })
  deleteImage(
    @Param('id') roomId: string,
    @Param('imgId') imageId: string,
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.deleteImage(roomId, imageId, user, msg);
  }

  @Patch(':id/images/:imgId/cover')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Dat anh lam anh bia' })
  setCoverImage(
    @Param('id') roomId: string,
    @Param('imgId') imageId: string,
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.roomsService.setCoverImage(roomId, imageId, user, msg);
  }
}
