import {
  Controller, Get, Post, Put, Delete,
  Body, Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { CustomersService } from './customers.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { Role } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Customers')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('customers')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CustomersController {
  constructor(private customersService: CustomersService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach khach hang' })
  @ApiQuery({ name: 'is_vip', required: false, type: Boolean })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'sort', required: false, enum: ['total_spent', 'newest'] })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  findAll(
    @Query('is_vip') isVip: boolean,
    @Query('search') search: string,
    @Query('sort') sort: string,
    @Query('page') page: number,
    @Query('limit') limit: number,
    @Lang() msg: Messages,
  ) {
    return this.customersService.findAll(msg, { isVip, search, sort, page, limit });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiet khach hang kem lich su booking' })
  findOne(@Param('id') id: string, @Lang() msg: Messages) {
    return this.customersService.findOne(id, msg);
  }

  @Post()
  @ApiOperation({ summary: 'Tao ho so khach moi' })
  create(@Body() dto: CreateCustomerDto, @Lang() msg: Messages) {
    return this.customersService.create(dto, msg);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Cap nhat thong tin khach' })
  update(@Param('id') id: string, @Body() dto: UpdateCustomerDto, @Lang() msg: Messages) {
    return this.customersService.update(id, dto, msg);
  }

  @Delete(':id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Xoa ho so khach (chi khi khong con booking active)' })
  remove(@Param('id') id: string, @Lang() msg: Messages) {
    return this.customersService.remove(id, msg);
  }

  @Get(':id/bookings')
  @ApiOperation({ summary: 'Lich su booking cua khach' })
  getBookings(@Param('id') id: string, @Lang() msg: Messages) {
    return this.customersService.getBookings(id, msg);
  }

  @Get(':id/stats')
  @ApiOperation({ summary: 'Thong ke: tong booking, tong chi tieu, lan o gan nhat' })
  getStats(@Param('id') id: string, @Lang() msg: Messages) {
    return this.customersService.getStats(id, msg);
  }
}
