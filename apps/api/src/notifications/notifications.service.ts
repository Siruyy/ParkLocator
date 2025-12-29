import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from './entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationsRepository: Repository<Notification>,
  ) {}

  async create(userId: string, title: string, message: string, type: NotificationType = NotificationType.INFO) {
    const notification = this.notificationsRepository.create({
      userId,
      title,
      message,
      type,
    });
    return this.notificationsRepository.save(notification);
  }

  async findAll(userId: string) {
    return this.notificationsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(id: string, userId: string) {
    await this.notificationsRepository.update({ id, userId }, { isRead: true });
    return this.notificationsRepository.findOne({ where: { id } });
  }

  async markAllAsRead(userId: string) {
    await this.notificationsRepository.update({ userId, isRead: false }, { isRead: true });
    return { success: true };
  }
}
