import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Reservation, ReservationStatus } from '../reservations/entities/reservation.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Reservation)
    private reservationsRepository: Repository<Reservation>,
    private dataSource: DataSource,
  ) {}

  async getFinanceSummary() {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    // Helper to get stats for a date range
    const getStats = async (start: Date, end: Date) => {
      const { sum } = await this.reservationsRepository
        .createQueryBuilder('r')
        .select('SUM(r.amount)', 'sum')
        .where('r.status IN (:...statuses)', {
          statuses: [ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN, ReservationStatus.COMPLETED]
        })
        .andWhere('r.created_at >= :start AND r.created_at <= :end', { start, end })
        .getRawOne();

      const count = await this.reservationsRepository.count({
        where: (qb) => {
          qb.where('status IN (:...statuses)', {
            statuses: [ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN, ReservationStatus.COMPLETED]
          })
          .andWhere('created_at >= :start AND created_at <= :end', { start, end });
        }
      });

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

  async getRevenueStats(period: 'day' | 'month') {
    // Aggregate revenue by date
    const dateFormat = period === 'day' ? 'YYYY-MM-DD' : 'YYYY-MM';
    
    // Note: This is Postgres specific syntax
    const query = this.reservationsRepository
      .createQueryBuilder('r')
      .select(`TO_CHAR(r.created_at, '${dateFormat}')`, 'date')
      .addSelect('SUM(r.amount)', 'revenue')
      .where('r.status IN (:...statuses)', { 
        statuses: [ReservationStatus.CONFIRMED, ReservationStatus.CHECKED_IN, ReservationStatus.COMPLETED] 
      })
      .groupBy('date')
      .orderBy('date', 'ASC')
      .limit(30); // Last 30 periods

    const result = await query.getRawMany();
    
    return result.map(r => ({
      date: r.date,
      revenue: parseFloat(r.revenue)
    }));
  }

  async getTransactions(page: number, limit: number) {
    const [data, total] = await this.reservationsRepository.findAndCount({
      relations: ['user', 'venue', 'level', 'spot'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return { data, total };
  }

  async getLogs(page: number, limit: number) {
    // For MVP, we'll treat reservations as the source of truth for logs
    // In a real system, we'd query a dedicated AuditLog table
    const [data, total] = await this.reservationsRepository.findAndCount({
      relations: ['user', 'venue'],
      order: { updatedAt: 'DESC' }, // Show most recent updates
      skip: (page - 1) * limit,
      take: limit,
    });

    // Transform to a log-like structure
    const logs = data.map(r => ({
      id: r.id,
      action: this.getActionFromStatus(r.status),
      details: `Reservation ${(r.qrCode || 'UNKNOWN').substring(0, 8)} at ${r.venue?.name || 'Unknown Venue'}`,
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
