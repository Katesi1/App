import {
  Controller, Get, Post, Put, Patch, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingDto } from './dto/update-booking.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { BookingStatus, Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Bookings')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('bookings')
@UseGuards(JwtAuthGuard, RolesGuard)
export class BookingsController {
  constructor(private bookingsService: BookingsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach booking, filter theo status, room_id, customer_id, date_range, source' })
  @ApiQuery({ name: 'status', enum: BookingStatus, required: false })
  @ApiQuery({ name: 'room_id', required: false })
  @ApiQuery({ name: 'customer_id', required: false })
  @ApiQuery({ name: 'start_date', required: false })
  @ApiQuery({ name: 'end_date', required: false })
  @ApiQuery({ name: 'source', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(
    @CurrentUser() user: any,
    @Query('status') status: BookingStatus,
    @Query('room_id') roomId: string,
    @Query('customer_id') customerId: string,
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('source') source: string,
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Lang() msg: Messages,
  ) {
    return this.bookingsService.findAll(user, msg, {
      status, roomId, customerId, startDate, endDate, source, page, limit,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiet booking kem thong tin phong, khach, lich su thanh toan' })
  findOne(@Param('id') id: string, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.findOne(id, user, msg);
  }

  @Post()
  @ApiOperation({ summary: 'Tao booking moi (hold/confirm)' })
  create(@Body() dto: CreateBookingDto, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.create(dto, user, msg);
  }

  @Put(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat thong tin booking (ngay, so khach, gia)' })
  update(@Param('id') id: string, @Body() dto: UpdateBookingDto, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.update(id, dto, user, msg);
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Chuyen trang thai booking (hold -> confirmed -> checked_in...)' })
  updateStatus(
    @Param('id') id: string,
    @Body('status') status: BookingStatus,
    @Body('cancelReason') cancelReason: string,
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.bookingsService.updateStatus(id, status, user, msg, cancelReason);
  }

  @Post(':id/checkin')
  @ApiOperation({ summary: 'Check-in: cap nhat trang thai phong -> occupied' })
  checkin(@Param('id') id: string, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.checkin(id, user, msg);
  }

  @Post(':id/checkout')
  @ApiOperation({ summary: 'Check-out: cap nhat phong -> vacant, tong ket bill' })
  checkout(@Param('id') id: string, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.checkout(id, user, msg);
  }

  @Post(':id/cancel')
  @ApiOperation({ summary: 'Huy booking kem ly do, trigger hoan tien neu co' })
  cancel(
    @Param('id') id: string,
    @Body('cancelReason') cancelReason: string,
    @CurrentUser() user: any,
    @Lang() msg: Messages,
  ) {
    return this.bookingsService.cancel(id, user, msg, cancelReason);
  }

  @Delete(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xoa booking (chi khi status = hold)' })
  remove(@Param('id') id: string, @CurrentUser() user: any, @Lang() msg: Messages) {
    return this.bookingsService.remove(id, user, msg);
  }
}
