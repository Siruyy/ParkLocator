/* eslint-disable @typescript-eslint/no-unsafe-member-access */
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
  async getFinanceSummary(@Request() req) {
    const data = await this.reportsService.getFinanceSummary(req.user);
    return {
      success: true,
      data,
    };
  }

  @Get('revenue')
  async getRevenueStats(
    @Request() req,
    @Query('period') period: 'day' | 'month' = 'day',
  ) {
    const data = await this.reportsService.getRevenueStats(period, req.user);
    return {
      success: true,
      data,
    };
  }

  @Get('transactions')
  async getTransactions(
    @Request() req,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 10,
    @Query('search') search?: string,
  ) {
    const { data, total } = await this.reportsService.getTransactions(
      page,
      limit,
      req.user,
      search,
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
    @Request() req,
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
    @Query('search') search?: string,
  ) {
    // For MVP, logs are essentially reservation history/events
    const { data, total } = await this.reportsService.getLogs(
      page,
      limit,
      req.user,
      search,
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

  @Get('audit-logs')
  @Roles(UserRole.SUPER_ADMIN)
  async getAuditLogs(
    @Query('page') page: number = 1,
    @Query('limit') limit: number = 20,
    @Query('search') search?: string,
    @Query('action') action?: string,
  ) {
    const { data, total } = await this.reportsService.getAuditLogs(
      page,
      limit,
      search,
      action,
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
}
