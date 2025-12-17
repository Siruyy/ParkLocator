import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('summary')
  async getFinanceSummary() {
    const data = await this.reportsService.getFinanceSummary();
    return {
      success: true,
      data,
    };
  }

  @Get('revenue')
  async getRevenueStats(@Query('period') period: 'day' | 'month' = 'day') {
    const data = await this.reportsService.getRevenueStats(period);
    return {
      success: true,
      data,
    };
  }

  @Get('transactions')
  async getTransactions(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
  ) {
    const { data, total } = await this.reportsService.getTransactions(
      page,
      limit,
    );
    return {
      success: true,
      data,
      meta: {
        total,
        page,
        limit,
      },
    };
  }

  @Get('logs')
  async getLogs(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
  ) {
    // For MVP, logs are essentially reservation history/events
    const { data, total } = await this.reportsService.getLogs(page, limit);
    return {
      success: true,
      data,
      meta: {
        total,
        page,
        limit,
      },
    };
  }
}
