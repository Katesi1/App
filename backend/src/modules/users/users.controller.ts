import {
  Controller, Get, Post, Put, Patch, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Users')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Danh sach nhan vien cua property' })
  findAll(
    @Query('role') role: Role,
    @CurrentUser() currentUser: any,
    @Lang() msg: Messages,
  ) {
    return this.usersService.findAll(msg, currentUser, role);
  }

  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Chi tiet nhan vien' })
  findOne(@Param('id') id: string, @Lang() msg: Messages) {
    return this.usersService.findOne(id, msg);
  }

  @Post()
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Tao tai khoan nhan vien moi' })
  create(
    @Body() dto: CreateUserDto,
    @CurrentUser() currentUser: any,
    @Lang() msg: Messages,
  ) {
    return this.usersService.create(dto, currentUser, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat thong tin nhan vien' })
  update(@Param('id') id: string, @Body() dto: UpdateUserDto, @Lang() msg: Messages) {
    return this.usersService.update(id, dto, msg);
  }

  @Patch(':id/role')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Thay doi vai tro nhan vien' })
  updateRole(@Param('id') id: string, @Body('role') role: Role, @Lang() msg: Messages) {
    return this.usersService.updateRole(id, role, msg);
  }

  @Patch('me/password')
  @ApiOperation({ summary: 'Nguoi dung tu doi mat khau' })
  changePassword(
    @CurrentUser('id') userId: string,
    @Body() dto: ChangePasswordDto,
    @Lang() msg: Messages,
  ) {
    return this.usersService.changePassword(userId, dto, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Vo hieu hoa tai khoan nhan vien' })
  remove(
    @Param('id') id: string,
    @CurrentUser('id') currentUserId: string,
    @Lang() msg: Messages,
  ) {
    return this.usersService.remove(id, currentUserId, msg);
  }
}
