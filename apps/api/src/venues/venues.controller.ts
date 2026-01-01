/* eslint-disable @typescript-eslint/no-unsafe-member-access */

/* eslint-disable @typescript-eslint/no-unsafe-argument */
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  ParseUUIDPipe,
  Request,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { VenuesService } from './venues.service';
import {
  CreateVenueDto,
  UpdateVenueDto,
  CreateLevelDto,
  UpdateLevelDto,
  UpdateVenueConfigurationDto,
} from './dto';
import { SpotStatus } from './entities';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { LoggingInterceptor } from '../common/interceptors/logging.interceptor';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '../users/entities/user.entity';
import type { AuthUser } from '../auth/types/auth-user.type';

@Controller('venues')
export class VenuesController {
  constructor(private readonly venuesService: VenuesService) {}

  // ==================== PUBLIC ENDPOINTS ====================

  @Get('nearby')
  async findNearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radius') radius?: string,
  ) {
    const venues = await this.venuesService.findNearby(
      parseFloat(lat),
      parseFloat(lng),
      radius ? parseFloat(radius) : 5,
    );

    return venues;
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  async findAll(@Request() req) {
    // If public (no user), return all active venues (or maybe restricted list?)
    // For now, let's assume public can see all, but if logged in as manager, we filter.
    // Actually, the mobile app calls this publicly.
    // So we need to check if req.user exists.

    const venues = await this.venuesService.findAll(req.user);

    return venues;
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const venue = await this.venuesService.findOne(id);

    return venue;
  }

  @Get(':id/availability')
  async getAvailability(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('startAt') startAt?: string,
    @Query('endAt') endAt?: string,
  ) {
    const startDate = startAt ? new Date(startAt) : undefined;
    const endDate = endAt ? new Date(endAt) : undefined;

    const availability = await this.venuesService.getAvailability(
      id,
      startDate,
      endDate,
    );

    return {
      success: true,
      data: availability,
      meta: {
        venueId: id,
        startAt: startAt || null,
        endAt: endAt || null,
        timestamp: new Date().toISOString(),
      },
    };
  }

  @Get(':id/levels')
  async findLevelsByVenue(@Param('id', ParseUUIDPipe) id: string) {
    const levels = await this.venuesService.findLevelsByVenue(id);

    return {
      success: true,
      data: levels,
      meta: { count: levels.length },
    };
  }

  @Get('levels/:id')
  async findLevel(
    @Param('id', ParseUUIDPipe) id: string,
    @Query('startAt') startAt?: string,
    @Query('endAt') endAt?: string,
  ) {
    const startDate = startAt ? new Date(startAt) : undefined;
    const endDate = endAt ? new Date(endAt) : undefined;

    const level = await this.venuesService.findLevelWithSpots(
      id,
      startDate,
      endDate,
    );

    return {
      success: true,
      data: level,
    };
  }

  // ==================== PROTECTED ENDPOINTS (MANAGER ONLY) ====================

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  @UseInterceptors(
    FileInterceptor('image', {
      storage: diskStorage({
        destination: './uploads/venues',
        filename: (req, file, cb) => {
          const randomName = Array(32)
            .fill(null)
            .map(() => Math.round(Math.random() * 16).toString(16))
            .join('');
          return cb(null, `${randomName}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async create(
    @Body() createVenueDto: CreateVenueDto,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() currentUser: AuthUser,
  ) {
    if (file) {
      createVenueDto.imageUrl = `/uploads/venues/${file.filename}`;
    }
    const venue = await this.venuesService.create(
      createVenueDto,
      currentUser.userId,
    );

    return {
      success: true,
      data: venue,
      message: 'Venue created successfully',
    };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  @UseInterceptors(
    LoggingInterceptor,
    FileInterceptor('image', {
      storage: diskStorage({
        destination: './uploads/venues',
        filename: (req, file, cb) => {
          const randomName = Array(32)
            .fill(null)
            .map(() => Math.round(Math.random() * 16).toString(16))
            .join('');
          return cb(null, `${randomName}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateVenueDto: UpdateVenueDto,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() currentUser: AuthUser,
  ) {
    if (file) {
      updateVenueDto.imageUrl = `/uploads/venues/${file.filename}`;
    }
    const venue = await this.venuesService.update(
      id,
      updateVenueDto,
      currentUser.userId,
    );

    return {
      success: true,
      data: venue,
      message: 'Venue updated successfully',
    };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() currentUser: AuthUser,
  ) {
    await this.venuesService.remove(id, currentUser.userId);

    return {
      success: true,
      message: 'Venue deleted successfully',
    };
  }

  @Post(':id/restore')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async restore(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() currentUser: AuthUser,
  ) {
    const venue = await this.venuesService.restore(id, currentUser.userId);

    return {
      success: true,
      data: venue,
      message: 'Venue restored successfully',
    };
  }

  @Post(':id/levels')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async createLevel(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createLevelDto: CreateLevelDto,
    @CurrentUser() currentUser: AuthUser,
  ) {
    const level = await this.venuesService.createLevel(
      id,
      createLevelDto,
      currentUser.userId,
    );

    return {
      success: true,
      data: level,
      message: 'Level created successfully',
    };
  }

  // ==================== CONFIGURATION ENDPOINTS ====================

  @Get(':id/configuration')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async getConfiguration(@Param('id', ParseUUIDPipe) id: string) {
    const config = await this.venuesService.getVenueConfiguration(id);

    return {
      success: true,
      data: config,
    };
  }

  @Patch(':id/configuration')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async updateConfiguration(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateVenueConfigurationDto: UpdateVenueConfigurationDto,
    @CurrentUser() currentUser: AuthUser,
  ) {
    const config = await this.venuesService.updateVenueConfiguration(
      id,
      updateVenueConfigurationDto,
      currentUser.userId,
    );

    return {
      success: true,
      data: config,
      message: 'Venue configuration updated successfully',
    };
  }
}

@Controller('levels')
export class LevelsController {
  constructor(private readonly venuesService: VenuesService) {}

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const level = await this.venuesService.findLevelWithSpots(id);

    return {
      success: true,
      data: level,
    };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateLevelDto: UpdateLevelDto,
    @CurrentUser() currentUser: AuthUser,
  ) {
    const level = await this.venuesService.updateLevel(
      id,
      updateLevelDto,
      currentUser.userId,
    );

    return {
      success: true,
      data: level,
      message: 'Level updated successfully',
    };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() currentUser: AuthUser,
  ) {
    await this.venuesService.removeLevel(id, currentUser.userId);

    return {
      success: true,
      message: 'Level deleted successfully',
    };
  }
}

@Controller('spots')
export class SpotsController {
  constructor(private readonly venuesService: VenuesService) {}

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPER_ADMIN)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: SpotStatus,
    @CurrentUser() currentUser: AuthUser,
  ) {
    const spot = await this.venuesService.updateSpotStatus(
      id,
      status,
      currentUser.userId,
    );

    return {
      success: true,
      data: spot,
      message: 'Spot status updated successfully',
    };
  }
}
