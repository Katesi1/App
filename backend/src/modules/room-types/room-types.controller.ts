import {
  Controller, Get, Post, Put, Delete,
  Body, Param, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RoomTypesService } from './room-types.service';
import { CreateRoomTypeDto } from './dto/create-room-type.dto';
import { UpdateRoomTypeDto } from './dto/update-room-type.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Room Types')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('room-types')
@UseGuards(JwtAuthGuard, RolesGuard)
export class RoomTypesController {
  constructor(private roomTypesService: RoomTypesService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach loai phong' })
  findAll(@Lang() msg: Messages) {
    return this.roomTypesService.findAll(msg);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiet loai phong' })
  findOne(@Param('id') id: string, @Lang() msg: Messages) {
    return this.roomTypesService.findOne(id, msg);
  }

  @Post()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Tao loai phong moi' })
  create(@Body() dto: CreateRoomTypeDto, @Lang() msg: Messages) {
    return this.roomTypesService.create(dto, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat loai phong' })
  update(@Param('id') id: string, @Body() dto: UpdateRoomTypeDto, @Lang() msg: Messages) {
    return this.roomTypesService.update(id, dto, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xoa loai phong' })
  remove(@Param('id') id: string, @Lang() msg: Messages) {
    return this.roomTypesService.remove(id, msg);
  }
}
