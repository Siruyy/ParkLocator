import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuditService } from './audit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { IsString, IsOptional, IsObject } from 'class-validator';

export class ActivityLogDto {
  @IsString()
  action: string;

  @IsString()
  details: string;

  @IsString()
  @IsOptional()
  page?: string;

  @IsString()
  @IsOptional()
  element?: string;

  @IsString()
  @IsOptional()
  venueId?: string;

  @IsString()
  @IsOptional()
  venueName?: string;

  @IsObject()
  @IsOptional()
  metadata?: Record<string, any>;
}

@Controller('audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Post('activity')
  async logActivity(@Request() req, @Body() activityDto: ActivityLogDto) {
    try {
      let details = activityDto.details;
      
      // Add page info to details (but not for venue-specific actions that already have venue name)
      if (activityDto.page && !activityDto.venueName) {
        details = `${details} (Page: ${activityDto.page})`;
      }
      
      // Add venue name to details if present
      if (activityDto.venueName) {
        details = `${details} [Venue: ${activityDto.venueName}]`;
      }

      // Ensure action is never null/undefined
      const action = activityDto.action || 'UNKNOWN_ACTION';
      
      // Use venueId as resourceId if present, otherwise use element
      const resourceId = activityDto.venueId || activityDto.element || undefined;
      const resourceType = activityDto.venueId ? 'Venue' : 'Activity';

      await this.auditService.log(
        action,
        details || '',
        req.user?.userId,
        resourceId,
        resourceType,
        req.ip || undefined,
        undefined,
      );

      return { success: true };
    } catch (error) {
      console.error('Failed to log activity:', error);
      throw error;
    }
  }
}
