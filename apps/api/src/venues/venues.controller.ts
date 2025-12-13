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
} from '@nestjs/common';
import { VenuesService } from './venues.service';
import {
  CreateVenueDto,
  UpdateVenueDto,
  CreateLevelDto,
  UpdateLevelDto,
} from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, ROLES_KEY } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

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

    return {
      success: true,
      data: venues,
      meta: {
        count: venues.length,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        radiusKm: radius ? parseFloat(radius) : 5,
      },
    };
  }

  @Get()
  async findAll() {
    const venues = await this.venuesService.findAll();

    return {
      success: true,
      data: venues,
      meta: { count: venues.length },
    };
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const venue = await this.venuesService.findOne(id);

    return {
      success: true,
      data: venue,
    };
  }

  @Get(':id/availability')
  async getAvailability(@Param('id', ParseUUIDPipe) id: string) {
    const availability = await this.venuesService.getAvailability(id);

    return {
      success: true,
      data: availability,
      meta: {
        venueId: id,
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

  // ==================== PROTECTED ENDPOINTS (MANAGER ONLY) ====================

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER)
  async create(@Body() createVenueDto: CreateVenueDto) {
    const venue = await this.venuesService.create(createVenueDto);

    return {
      success: true,
      data: venue,
      message: 'Venue created successfully',
    };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateVenueDto: UpdateVenueDto,
  ) {
    const venue = await this.venuesService.update(id, updateVenueDto);

    return {
      success: true,
      data: venue,
      message: 'Venue updated successfully',
    };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER)
  async remove(@Param('id', ParseUUIDPipe) id: string) {
    await this.venuesService.remove(id);

    return {
      success: true,
      message: 'Venue deleted successfully',
    };
  }

  @Post(':id/levels')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER)
  async createLevel(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() createLevelDto: CreateLevelDto,
  ) {
    const level = await this.venuesService.createLevel(id, createLevelDto);

    return {
      success: true,
      data: level,
      message: 'Level created successfully',
    };
  }
}

@Controller('levels')
export class LevelsController {
  constructor(private readonly venuesService: VenuesService) {}

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    const level = await this.venuesService.findLevel(id);

    return {
      success: true,
      data: level,
    };
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.MANAGER)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateLevelDto: UpdateLevelDto,
  ) {
    const level = await this.venuesService.updateLevel(id, updateLevelDto);

    return {
      success: true,
      data: level,
      message: 'Level updated successfully',
    };
  }
}
