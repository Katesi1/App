import {
  Controller, Get, Post, Put, Delete,
  Body, Param, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PropertiesService } from './properties.service';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Properties')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('properties')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PropertiesController {
  constructor(private propertiesService: PropertiesService) {}

  @Get()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Danh sach co so luu tru' })
  findAll(@CurrentUser() currentUser: any, @Lang() msg: Messages) {
    return this.propertiesService.findAll(msg, currentUser);
  }

  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Chi tiet co so luu tru' })
  findOne(@Param('id') id: string, @CurrentUser() currentUser: any, @Lang() msg: Messages) {
    return this.propertiesService.findOne(id, currentUser, msg);
  }

  @Get(':id/stats')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Thong ke tong quan co so' })
  getStats(@Param('id') id: string, @CurrentUser() currentUser: any, @Lang() msg: Messages) {
    return this.propertiesService.getStats(id, currentUser, msg);
  }

  @Post()
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Tao moi co so luu tru' })
  create(@Body() dto: CreatePropertyDto, @CurrentUser() currentUser: any, @Lang() msg: Messages) {
    return this.propertiesService.create(dto, currentUser, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Cap nhat co so luu tru' })
  update(
    @Param('id') id: string,
    @Body() dto: UpdatePropertyDto,
    @CurrentUser() currentUser: any,
    @Lang() msg: Messages,
  ) {
    return this.propertiesService.update(id, dto, currentUser, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Xoa co so luu tru (soft delete)' })
  remove(@Param('id') id: string, @CurrentUser() currentUser: any, @Lang() msg: Messages) {
    return this.propertiesService.remove(id, currentUser, msg);
  }
}
