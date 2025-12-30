import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Brackets } from 'typeorm';
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
    changes?: { field: string; before: any; after: any }[],
  ): Promise<AuditLog> {
    const log = this.auditLogRepository.create({
      action,
      details,
      userId,
      resourceId,
      resourceType,
      ipAddress,
      changes,
    });
    return this.auditLogRepository.save(log);
  }

  /**
   * Helper to calculate changes between two objects
   */
  calculateChanges(before: Record<string, any>, after: Record<string, any>, fieldsToTrack?: string[]): { field: string; before: any; after: any }[] {
    const changes: { field: string; before: any; after: any }[] = [];
    const keys = fieldsToTrack || Object.keys({ ...before, ...after });
    
    for (const key of keys) {
      if (key === 'password' || key === 'updatedAt' || key === 'createdAt') continue;
      
      const beforeVal = before[key];
      const afterVal = after[key];
      
      if (JSON.stringify(beforeVal) !== JSON.stringify(afterVal)) {
        changes.push({
          field: key,
          before: beforeVal ?? null,
          after: afterVal ?? null,
        });
      }
    }
    
    return changes;
  }

  async findAll(page: number = 1, limit: number = 20, search?: string, action?: string): Promise<{ data: AuditLog[]; total: number }> {
    const query = this.auditLogRepository.createQueryBuilder('log')
      .leftJoinAndSelect('log.user', 'user')
      .orderBy('log.createdAt', 'DESC');

    if (action) {
      query.andWhere('log.action = :action', { action });
    }

    if (search && search.trim().length > 0) {
      const searchTerm = `%${search.trim()}%`;
      query.where(new Brackets(qb => {
        qb.where('user.email ILIKE :search', { search: searchTerm })
          .orWhere('log.action ILIKE :search', { search: searchTerm })
          .orWhere('log.details ILIKE :search', { search: searchTerm });
      }));
    }

    // Apply pagination after filters
    query.skip((page - 1) * limit).take(limit);

    const [data, total] = await query.getManyAndCount();
    return { data, total };
  }
}
