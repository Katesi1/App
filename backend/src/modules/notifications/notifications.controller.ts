import {
  Controller, Get, Patch, Delete,
  Param, Query, UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Lang } from '../../common/decorators/lang.decorator';
import { NotificationType } from '@prisma/client';
import type { Messages } from '../../i18n';

@ApiTags('Notifications')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'Accept-Language', enum: ['en', 'vi'], required: false })
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sach thong bao cua user hien tai' })
  @ApiQuery({ name: 'is_read', required: false, type: Boolean })
  @ApiQuery({ name: 'type', enum: NotificationType, required: false })
  findAll(
    @CurrentUser('id') userId: string,
    @Query('is_read') isRead: boolean,
    @Query('type') type: NotificationType,
    @Lang() msg: Messages,
  ) {
    return this.notificationsService.findAll(userId, msg, { isRead, type });
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Danh dau da doc' })
  markAsRead(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Lang() msg: Messages,
  ) {
    return this.notificationsService.markAsRead(id, userId, msg);
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Danh dau tat ca da doc' })
  markAllAsRead(@CurrentUser('id') userId: string, @Lang() msg: Messages) {
    return this.notificationsService.markAllAsRead(userId, msg);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Xoa thong bao' })
  remove(
    @Param('id') id: string,
    @CurrentUser('id') userId: string,
    @Lang() msg: Messages,
  ) {
    return this.notificationsService.remove(id, userId, msg);
  }
}
