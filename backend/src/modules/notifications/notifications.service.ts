import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { NotificationsRepository } from './notifications.repository';
import { Messages } from '../../i18n';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
  constructor(private repo: NotificationsRepository) {}

  async findAll(userId: string, msg: Messages, query: { isRead?: boolean; type?: NotificationType }) {
    const where: any = { userId };
    if (query.isRead !== undefined) where.isRead = query.isRead;
    if (query.type) where.type = query.type;

    const notifications = await this.repo.findAll(where);
    return { message: msg.notifications.listSuccess, data: notifications };
  }

  async markAsRead(id: string, userId: string, msg: Messages) {
    const notification = await this.repo.findByIdAndUser(id, userId);
    if (!notification) throw new NotFoundException(msg.notifications.notFound);

    const updated = await this.repo.markAsRead(id);
    return { message: msg.notifications.readSuccess, data: updated };
  }

  async markAllAsRead(userId: string, msg: Messages) {
    await this.repo.markAllAsRead(userId);
    return { message: msg.notifications.readAllSuccess, data: null };
  }

  async remove(id: string, userId: string, msg: Messages) {
    const notification = await this.repo.findByIdAndUser(id, userId);
    if (!notification) throw new NotFoundException(msg.notifications.notFound);

    await this.repo.delete(id);
    return { message: msg.notifications.deleteSuccess, data: null };
  }

  async createNotification(data: {
    userId: string;
    bookingId?: string;
    title: string;
    body: string;
    type: NotificationType;
  }) {
    return this.repo.create({
      user: { connect: { id: data.userId } },
      ...(data.bookingId ? { booking: { connect: { id: data.bookingId } } } : {}),
      title: data.title,
      body: data.body,
      type: data.type,
    });
  }
}
