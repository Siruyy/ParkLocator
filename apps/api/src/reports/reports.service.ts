import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, Brackets } from 'typeorm';
import { Reservation, ReservationStatus } from '../reservations/entities/reservation.entity';
import { UserRole } from '../users/entities/user.entity';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Reservation)
    private reservationsRepository: Repository<Reservation>,
    private dataSource: DataSource,
    private auditService: AuditService,
  ) {}

  async getAuditLogs(page: number, limit: number, search?: string) {
    return this.auditService.findAll(page, limit, search);
  }

  async getFinanceSummary(user: any) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    const isManager = user.role === UserRole.MANAGER;
    const venueId = user.venueId;

    // Helper to get stats for a date range
    const getStats = async (start: Date, end: Date) => {
      const query = this.reservationsRepository
        .createQueryBuilder('r')
        .where('r.status IN (:...statuses)', {
          statuses: [ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN, ReservationStatus.COMPLETED]
        })
        .andWhere('r.created_at >= :start AND r.created_at <= :end', { start, end });

      if (isManager) {
        query.andWhere('r.venueId = :venueId', { venueId });
      }

      const { sum } = await query.select('SUM(r.amount)', 'sum').getRawOne();
      const count = await query.getCount();

      return { revenue: parseFloat(sum || '0'), transactions: count };
    };

    // Current Month Stats
    const currentMonthStats = await getStats(startOfMonth, now);
    
    // Last Month Stats (Full month for comparison)
    const lastMonthStats = await getStats(startOfLastMonth, endOfLastMonth);

    // Calculate Trends
    const calculateTrend = (current: number, previous: number) => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return ((current - previous) / previous) * 100;
    };

    const revenueTrend = calculateTrend(currentMonthStats.revenue, lastMonthStats.revenue);
    const transactionsTrend = calculateTrend(currentMonthStats.transactions, lastMonthStats.transactions);

    // Daily Average Revenue (Current Month)
    const daysPassed = Math.max(1, now.getDate());
    const dailyAverageRevenue = currentMonthStats.revenue / daysPassed;

    // Avg Ticket Size (All time or current month? Let's do current month for consistency with summary)
    const avgTicketSize = currentMonthStats.transactions > 0 
      ? currentMonthStats.revenue / currentMonthStats.transactions 
      : 0;

    return {
      totalRevenue: currentMonthStats.revenue,
      totalTransactions: currentMonthStats.transactions,
      dailyAverageRevenue, // Replaces pendingRefunds
      avgTicketSize,
      trends: {
        revenue: revenueTrend,
        transactions: transactionsTrend
      }
    };
  }

  async getRevenueStats(period: 'day' | 'month', user: any) {
    // Aggregate revenue by date
    const dateFormat = period === 'day' ? 'YYYY-MM-DD' : 'YYYY-MM';
    const isManager = user.role === UserRole.MANAGER;
    
    // Note: This is Postgres specific syntax
    const query = this.reservationsRepository
      .createQueryBuilder('r')
      .select(`TO_CHAR(r.created_at, '${dateFormat}')`, 'date')
      .addSelect('SUM(r.amount)', 'revenue')
      .where('r.status IN (:...statuses)', { 
        statuses: [ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN, ReservationStatus.COMPLETED] 
      });

    if (isManager) {
      query.andWhere('r.venueId = :venueId', { venueId: user.venueId });
    }

    query
      .groupBy('date')
      .orderBy('date', 'ASC')
      .limit(30); // Last 30 periods

    const result = await query.getRawMany();
    
    return result.map(r => ({
      date: r.date,
      revenue: parseFloat(r.revenue)
    }));
  }

  async getTransactions(page: number, limit: number, user: any, search?: string) {
    const query = this.reservationsRepository.createQueryBuilder('r')
      .leftJoinAndSelect('r.user', 'user')
      .leftJoinAndSelect('r.venue', 'venue')
      .leftJoinAndSelect('r.level', 'level')
      .leftJoinAndSelect('r.spot', 'spot')
      .orderBy('r.createdAt', 'DESC');

    if (user.role === UserRole.MANAGER) {
      query.andWhere('r.venueId = :venueId', { venueId: user.venueId });
    }

    if (search && search.trim().length > 0) {
      const searchTerm = `%${search.trim()}%`;
      query.andWhere(new Brackets(qb => {
        qb.where('user.email ILIKE :search', { search: searchTerm })
          .orWhere('venue.name ILIKE :search', { search: searchTerm })
          .orWhere('r.id::text ILIKE :search', { search: searchTerm });
      }));
    }

    // Apply pagination after filters
    query.skip((page - 1) * limit).take(limit);

    const [data, total] = await query.getManyAndCount();

    return { data, total };
  }

  async getLogs(page: number, limit: number, user: any, search?: string) {
    // For MVP, we'll treat reservations as the source of truth for logs
    // In a real system, we'd query a dedicated AuditLog table
    const query = this.reservationsRepository.createQueryBuilder('r')
      .leftJoinAndSelect('r.user', 'user')
      .leftJoinAndSelect('r.venue', 'venue')
      .orderBy('r.updatedAt', 'DESC');

    if (user.role === UserRole.MANAGER) {
      query.andWhere('r.venueId = :venueId', { venueId: user.venueId });
    }

    if (search && search.trim().length > 0) {
      const searchTerm = `%${search.trim()}%`;
      query.andWhere(new Brackets(qb => {
        qb.where('user.email ILIKE :search', { search: searchTerm })
          .orWhere('venue.name ILIKE :search', { search: searchTerm })
          .orWhere('r.id::text ILIKE :search', { search: searchTerm })
          .orWhere('r.qrCode ILIKE :search', { search: searchTerm });
      }));
    }

    // Apply pagination after filters
    query.skip((page - 1) * limit).take(limit);

    const [data, total] = await query.getManyAndCount();

    // Transform to a log-like structure
    const logs = data.map(r => ({
      id: r.id,
      action: this.getActionFromStatus(r.status),
      details: `${r.type === 'immediate' ? 'Book Now' : 'Reservation'} ${(r.qrCode || 'UNKNOWN').substring(0, 8)} at ${r.venue?.name || 'Unknown Venue'}`,
      user: r.user?.email || 'Deleted User',
      timestamp: r.updatedAt,
      status: r.status
    }));

    return { data: logs, total };
  }

  private getActionFromStatus(status: ReservationStatus): string {
    switch (status) {
      case ReservationStatus.PENDING: return 'Reservation Created';
      case ReservationStatus.CONFIRMED: return 'Payment Confirmed';
      case ReservationStatus.CHECKED_IN: return 'Vehicle Entry';
      case ReservationStatus.COMPLETED: return 'Vehicle Exit';
      case ReservationStatus.CANCELLED: return 'Reservation Cancelled';
      default: return 'System Update';
    }
  }
}
