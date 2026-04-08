import {
  Controller, Get, Post, Patch,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { PaymentStatus, Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Payments')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('payments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Get()
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Danh sach thanh toan' })
  @ApiQuery({ name: 'booking_id', required: false })
  @ApiQuery({ name: 'method', required: false })
  @ApiQuery({ name: 'status', enum: PaymentStatus, required: false })
  @ApiQuery({ name: 'start_date', required: false })
  @ApiQuery({ name: 'end_date', required: false })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(
    @Query('booking_id') bookingId: string,
    @Query('method') method: string,
    @Query('status') status: PaymentStatus,
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Lang() msg: Messages,
  ) {
    return this.paymentsService.findAll(msg, { bookingId, method, status, startDate, endDate, page, limit });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiet giao dich' })
  findOne(@Param('id') id: string, @Lang() msg: Messages) {
    return this.paymentsService.findOne(id, msg);
  }

  @Post()
  @ApiOperation({ summary: 'Ghi nhan thanh toan (coc / full / phu phi / hoan tien)' })
  create(
    @Body() dto: CreatePaymentDto,
    @CurrentUser('id') userId: string,
    @Lang() msg: Messages,
  ) {
    return this.paymentsService.create(dto, userId, msg);
  }

  @Patch(':id/status')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cap nhat trang thai giao dich (pending -> completed / failed)' })
  updateStatus(
    @Param('id') id: string,
    @Body('status') status: PaymentStatus,
    @Lang() msg: Messages,
  ) {
    return this.paymentsService.updateStatus(id, status, msg);
  }

  @Post('booking/:bookingId')
  @ApiOperation({ summary: 'Tao thanh toan gan truc tiep voi booking (shortcut)' })
  createForBooking(
    @Param('bookingId') bookingId: string,
    @Body() dto: CreatePaymentDto,
    @CurrentUser('id') userId: string,
    @Lang() msg: Messages,
  ) {
    return this.paymentsService.createForBooking(bookingId, dto, userId, msg);
  }
}
