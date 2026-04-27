import {
  Controller, Get,
  Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Reports')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ReportsController {
  constructor(private reportsService: ReportsService) {}

  @Get('revenue')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Doanh thu theo ngay/tuan/thang' })
  @ApiQuery({ name: 'start_date', required: true })
  @ApiQuery({ name: 'end_date', required: true })
  @ApiQuery({ name: 'property_id', required: false })
  @ApiQuery({ name: 'period', required: false, enum: ['day', 'week', 'month'] })
  getRevenue(
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('property_id') propertyId: string,
    @Query('period') period: string,
    @Lang() msg: Messages,
  ) {
    return this.reportsService.getRevenue(msg, { startDate, endDate, propertyId, period });
  }

  @Get('occupancy')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Cong suat phong theo thoi gian' })
  @ApiQuery({ name: 'start_date', required: true })
  @ApiQuery({ name: 'end_date', required: true })
  @ApiQuery({ name: 'property_id', required: false })
  getOccupancy(
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('property_id') propertyId: string,
    @Lang() msg: Messages,
  ) {
    return this.reportsService.getOccupancy(msg, { startDate, endDate, propertyId });
  }

  @Get('bookings-summary')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Tong hop booking: so luong theo trang thai, nguon, ty le huy' })
  @ApiQuery({ name: 'start_date', required: true })
  @ApiQuery({ name: 'end_date', required: true })
  @ApiQuery({ name: 'property_id', required: false })
  getBookingsSummary(
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('property_id') propertyId: string,
    @Lang() msg: Messages,
  ) {
    return this.reportsService.getBookingsSummary(msg, { startDate, endDate, propertyId });
  }

  @Get('top-rooms')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xep hang phong theo doanh thu va so dem' })
  @ApiQuery({ name: 'start_date', required: true })
  @ApiQuery({ name: 'end_date', required: true })
  @ApiQuery({ name: 'property_id', required: false })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  getTopRooms(
    @Query('start_date') startDate: string,
    @Query('end_date') endDate: string,
    @Query('property_id') propertyId: string,
    @Query('limit') limit: number,
    @Lang() msg: Messages,
  ) {
    return this.reportsService.getTopRooms(msg, { startDate, endDate, propertyId, limit });
  }

  @Get('dashboard-stats')
  @ApiOperation({ summary: 'Tong hop KPI cho man Dashboard' })
  @ApiQuery({ name: 'property_id', required: false })
  getDashboardStats(
    @Query('property_id') propertyId: string,
    @Lang() msg: Messages,
  ) {
    return this.reportsService.getDashboardStats(msg, propertyId);
  }
}
