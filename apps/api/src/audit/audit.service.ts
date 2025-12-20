import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './entities/audit-log.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private auditLogRepository: Repository<AuditLog>,
  ) {}

  async log(
    action: string,
    details: string,
    userId: string,
    resourceId?: string,
    resourceType?: string,
    ipAddress?: string,
  ): Promise<AuditLog> {
    const log = this.auditLogRepository.create({
      action,
      details,
      userId,
      resourceId,
      resourceType,
      ipAddress,
    });
    return this.auditLogRepository.save(log);
  }

  async findAll(page: number = 1, limit: number = 20, search?: string): Promise<{ data: AuditLog[]; total: number }> {
    const query = this.auditLogRepository.createQueryBuilder('log')
      .leftJoinAndSelect('log.user', 'user')
      .orderBy('log.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (search) {
      query.where('user.email ILIKE :search', { search: `%${search}%` })
        .orWhere('log.action ILIKE :search', { search: `%${search}%` })
        .orWhere('log.details ILIKE :search', { search: `%${search}%` });
    }

    const [data, total] = await query.getManyAndCount();
    return { data, total };
  }
}
