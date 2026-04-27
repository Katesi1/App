import {
  Controller, Get, Post, Put, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AmenitiesService } from './amenities.service';
import { CreateAmenityDto } from './dto/create-amenity.dto';
import { UpdateAmenityDto } from './dto/update-amenity.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Amenities')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('amenities')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AmenitiesController {
  constructor(private amenitiesService: AmenitiesService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach tien nghi' })
  findAll(@Query('category') category: string, @Lang() msg: Messages) {
    return this.amenitiesService.findAll(msg, category);
  }

  @Post()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Tao tien nghi moi' })
  create(@Body() dto: CreateAmenityDto, @Lang() msg: Messages) {
    return this.amenitiesService.create(dto, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat tien nghi' })
  update(@Param('id') id: string, @Body() dto: UpdateAmenityDto, @Lang() msg: Messages) {
    return this.amenitiesService.update(id, dto, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xoa tien nghi' })
  remove(@Param('id') id: string, @Lang() msg: Messages) {
    return this.amenitiesService.remove(id, msg);
  }
}
