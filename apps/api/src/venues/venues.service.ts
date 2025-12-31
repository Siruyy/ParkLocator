import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Venue, Level, Spot, SpotStatus, VenueConfiguration } from './entities';
import {
  CreateVenueDto,
  UpdateVenueDto,
  NearbyVenueDto,
  CreateLevelDto,
  UpdateLevelDto,
  LevelAvailabilityDto,
  UpdateVenueConfigurationDto,
} from './dto';
import {
  Reservation,
  ReservationStatus,
} from '../reservations/entities/reservation.entity';

import { User, UserRole } from '../users/entities/user.entity';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class VenuesService {
  constructor(
    @InjectRepository(Venue)
    private venuesRepository: Repository<Venue>,
    @InjectRepository(Level)
    private levelsRepository: Repository<Level>,
    @InjectRepository(Spot)
    private spotsRepository: Repository<Spot>,
    @InjectRepository(VenueConfiguration)
    private venueConfigurationRepository: Repository<VenueConfiguration>,
    private dataSource: DataSource,
    private auditService: AuditService,
  ) {}

  // ==================== VENUE OPERATIONS ====================

  async create(createVenueDto: CreateVenueDto, currentUserId: string): Promise<Venue> {
    const { 
      latitude, longitude, name, address, description, imageUrl,
      supportsRealTimeBooking, supportsFutureBooking, requireVehicleDetails,
      hasCoveredParking, hasCCTV
    } = createVenueDto;

    // Use raw query to insert with PostGIS geography
    const result = await this.dataSource.query(
      `INSERT INTO venues (
        name, address, location, description, image_url,
        supports_real_time_booking, supports_future_booking, require_vehicle_details,
        has_covered_parking, has_cctv
      )
       VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        name,
        address,
        longitude,
        latitude,
        description || null,
        imageUrl || null,
        supportsRealTimeBooking ?? true,
        supportsFutureBooking ?? false,
        requireVehicleDetails ?? true,
        hasCoveredParking ?? false,
        hasCCTV ?? false
      ],
    );

    const venue = await this.findOne(result[0].id);

    await this.auditService.log(
      'CREATE_VENUE',
      `Created venue ${venue.name}`,
      currentUserId,
      venue.id,
      'Venue'
    );

    return venue;
  }

  async findAll(user?: User): Promise<Venue[]> {
    const where: any = { isActive: true };

    if (user && user.role === UserRole.MANAGER) {
      if (!user.venueId) {
        return []; // Manager with no venue assigned sees nothing
      }
      where.id = user.venueId;
    }

    return this.venuesRepository.find({
      where,
      relations: ['levels'],
    });
  }

  async findOne(id: string): Promise<Venue> {
    const venue = await this.venuesRepository.findOne({
      where: { id },
      relations: ['levels', 'configuration'],
    });

    if (!venue) {
      throw new NotFoundException(`Venue with ID ${id} not found`);
    }

    return venue;
  }

  async update(id: string, updateVenueDto: UpdateVenueDto, currentUserId: string): Promise<Venue> {
    const beforeVenue = await this.findOne(id);
    const beforeSnapshot = { ...beforeVenue };

    const { latitude, longitude, ...rest } = updateVenueDto;

    console.log('[VenuesService.update] Received update:', { latitude, longitude, rest });
    console.log('[VenuesService.update] Types:', { 
      latType: typeof latitude, 
      lngType: typeof longitude,
      latValue: latitude,
      lngValue: longitude 
    });

    // Update other fields FIRST (before location update, to avoid overwriting)
    Object.assign(beforeVenue, rest);
    await this.venuesRepository.save(beforeVenue);

    // Update location AFTER save if coordinates provided (handle both number and string)
    // This must come after save() because save() would overwrite the raw SQL location update
    const lat = latitude !== undefined && latitude !== null ? Number(latitude) : null;
    const lng = longitude !== undefined && longitude !== null ? Number(longitude) : null;

    if (lat !== null && lng !== null && !isNaN(lat) && !isNaN(lng)) {
      console.log('[VenuesService.update] Updating location to:', { lat, lng });
      await this.dataSource.query(
        `UPDATE venues SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
        [lng, lat, id],
      );
    } else {
      console.log('[VenuesService.update] NOT updating location - invalid values');
    }

    // Re-fetch the venue to get updated location coordinates
    const updatedVenue = await this.findOne(id);

    const changes = this.auditService.calculateChanges(
      beforeSnapshot,
      updatedVenue,
      Object.keys(updateVenueDto)
    );

    await this.auditService.log(
      'UPDATE_VENUE',
      `Updated venue ${updatedVenue.name}`,
      currentUserId,
      id,
      'Venue',
      undefined,
      changes
    );

    return updatedVenue;
  }

  async remove(id: string, currentUserId: string): Promise<void> {
    const venue = await this.findOne(id);
    
    // Use softRemove to set deleted_at timestamp
    await this.venuesRepository.softRemove(venue);

    await this.auditService.log(
      'DELETE_VENUE',
      `Deleted venue ${venue.name}`,
      currentUserId,
      id,
      'Venue'
    );
  }

  async restore(id: string, currentUserId: string): Promise<Venue> {
    // Find with deleted to restore
    const venue = await this.venuesRepository.findOne({
      where: { id },
      withDeleted: true,
    });

    if (!venue) {
      throw new NotFoundException(`Venue with ID ${id} not found`);
    }

    // Recover the entity
    await this.venuesRepository.recover(venue);

    await this.auditService.log(
      'RESTORE_VENUE',
      `Restored venue ${venue.name}`,
      currentUserId,
      id,
      'Venue'
    );

    return venue;
  }



  // ==================== NEARBY SEARCH ====================

  async findNearby(
    lat: number,
    lng: number,
    radiusKm: number = 5,
  ): Promise<NearbyVenueDto[]> {
    const radiusMeters = radiusKm * 1000;

    // PostGIS query to find venues within radius
    const venues = await this.venuesRepository
      .createQueryBuilder('venue')
      .leftJoinAndSelect('venue.levels', 'level', 'level.is_active = true')
      .addSelect(
        `ST_Distance(venue.location::geography, ST_MakePoint(:lng, :lat)::geography)`,
        'distance',
      )
      .where('venue.is_active = true')
      .andWhere(
        `ST_DWithin(venue.location::geography, ST_MakePoint(:lng, :lat)::geography, :radius)`,
      )
      .setParameters({ lat, lng, radius: radiusMeters })
      .orderBy('distance', 'ASC')
      .getRawAndEntities();

    return venues.entities.map((venue) => {
      const raw = venues.raw.find((r) => r.venue_id === venue.id);
      const distance = raw ? raw.distance : 0;
      const totalCapacity = venue.levels.reduce(
        (sum, level) => sum + level.totalCapacity,
        0,
      );
      const availableSpots = venue.levels.reduce(
        (sum, level) => sum + level.availableSpots,
        0,
      );

      return {
        id: venue.id,
        name: venue.name,
        address: venue.address,
        latitude: venue.latitude || 0,
        longitude: venue.longitude || 0,
        description: venue.description,
        imageUrl: venue.imageUrl,
        isActive: venue.isActive,
        createdAt: venue.createdAt.toISOString(),
        updatedAt: venue.updatedAt.toISOString(),
        distance: Math.round(parseFloat(raw.distance)),
        levelsCount: venue.levels.length,
        totalCapacity,
        availableSpots,
        supportsRealTimeBooking: venue.supportsRealTimeBooking,
        supportsFutureBooking: venue.supportsFutureBooking,
        requireVehicleDetails: venue.requireVehicleDetails,
        hasCoveredParking: venue.hasCoveredParking,
        hasCCTV: venue.hasCCTV,
      };
    });
  }

  // ==================== AVAILABILITY ====================

  /**
   * Get availability for a venue, optionally filtered by date range.
   * If startAt and endAt are provided, it calculates availability based on
   * spots that don't have overlapping reservations for that time period.
   */
  async getAvailability(
    venueId: string,
    startAt?: Date,
    endAt?: Date,
  ): Promise<LevelAvailabilityDto[]> {
    const venue = await this.findOne(venueId);

    // If no date range provided, return real-time availability (for "Book Now")
    if (!startAt || !endAt) {
      return venue.levels
        .filter((level) => level.isActive)
        .map((level) => ({
          id: level.id,
          levelNumber: level.levelNumber,
          name: level.name,
          totalCapacity: level.totalCapacity,
          availableSpots: level.availableSpots,
          isCovered: level.isCovered,
          occupancyPercent:
            level.totalCapacity > 0
              ? Math.round(
                  ((level.totalCapacity - level.availableSpots) /
                    level.totalCapacity) *
                    100,
                )
              : 0,
        }));
    }

    // For "Book for Later" - calculate availability based on overlapping reservations
    const results: LevelAvailabilityDto[] = [];

    for (const level of venue.levels.filter((l) => l.isActive)) {
      // Count spots that have overlapping reservations for the requested time range
      const reservedSpotsCount = (await this.dataSource
        .createQueryBuilder(Reservation, 'r')
        .select('COUNT(DISTINCT r.spot_id)', 'count')
        .innerJoin(Spot, 's', 's.id = r.spot_id')
        .where('s.level_id = :levelId', { levelId: level.id })
        .andWhere('r.status IN (:...activeStatuses)', {
          activeStatuses: [
            ReservationStatus.PENDING,
            ReservationStatus.CONFIRMED,
            ReservationStatus.CHECKED_IN,
          ],
        })
        .andWhere(
          // Overlap condition: reservation overlaps if it starts before our end AND ends after our start
          '(r.start_at < :endAt AND r.end_at > :startAt)',
          { startAt, endAt },
        )
        .getRawOne()) as { count: string } | undefined;

      const reservedCount = parseInt(reservedSpotsCount?.count || '0', 10);
      const availableSpots = Math.max(0, level.totalCapacity - reservedCount);

      results.push({
        id: level.id,
        levelNumber: level.levelNumber,
        name: level.name,
        totalCapacity: level.totalCapacity,
        availableSpots,
        isCovered: level.isCovered,
        occupancyPercent:
          level.totalCapacity > 0
            ? Math.round(
                ((level.totalCapacity - availableSpots) / level.totalCapacity) *
                  100,
              )
            : 0,
      });
    }

    return results;
  }

  // ==================== LEVEL OPERATIONS ====================

  async createLevel(
    venueId: string,
    createLevelDto: CreateLevelDto,
    currentUserId: string,
  ): Promise<Level> {
    const venue = await this.findOne(venueId);

    // Check if level number already exists for this venue
    const existingLevel = await this.levelsRepository.findOne({
      where: { venueId: venue.id, levelNumber: createLevelDto.levelNumber },
    });

    if (existingLevel) {
      throw new BadRequestException(
        `Level number ${createLevelDto.levelNumber} already exists for this venue`,
      );
    }

    const level = this.levelsRepository.create({
      ...createLevelDto,
      venueId: venue.id,
      availableSpots: createLevelDto.totalCapacity, // Initially all spots are available
      isCovered: createLevelDto.isCovered ?? false,
    });

    try {
      const savedLevel = await this.levelsRepository.save(level);

      // Create individual spots for the level
      const spots: Partial<Spot>[] = [];
      
      if (createLevelDto.sections && createLevelDto.sections.length > 0) {
        // Create spots based on sections
        for (const section of createLevelDto.sections) {
          for (let i = 1; i <= section.totalCapacity; i++) {
            spots.push({
              spotNumber: `${section.name}-${i.toString().padStart(3, '0')}`,
              levelId: savedLevel.id,
              status: SpotStatus.AVAILABLE,
              section: section.name,
              vehicleType: section.vehicleType || 'Car',
            });
          }
        }
      } else {
        // Default behavior: create spots sequentially
        // Use the first vehicle type from the level, or default to 'Car'
        const defaultVehicleType = (createLevelDto.vehicleTypes && createLevelDto.vehicleTypes.length > 0) 
          ? createLevelDto.vehicleTypes[0] 
          : 'Car';

        for (let i = 1; i <= createLevelDto.totalCapacity; i++) {
          spots.push({
            spotNumber: `${level.levelNumber}-${i.toString().padStart(3, '0')}`,
            levelId: savedLevel.id,
            status: SpotStatus.AVAILABLE,
            vehicleType: defaultVehicleType,
          });
        }
      }

      await this.spotsRepository.save(spots);

      await this.auditService.log(
        'CREATE_LEVEL',
        `Created level ${savedLevel.levelNumber} for venue ${venue.name}`,
        currentUserId,
        savedLevel.id,
        'Level'
      );

      return savedLevel;
    } catch (error) {
      // If spots creation fails, we should probably delete the level to maintain consistency
      // But for now, let's just log and rethrow
      console.error('Error creating level:', error);
      throw new BadRequestException('Failed to create level: ' + error.message);
    }
  }

  async findLevelsByVenue(venueId: string): Promise<Level[]> {
    await this.findOne(venueId); // Verify venue exists

    return this.levelsRepository.find({
      where: { venueId, isActive: true },
      order: { levelNumber: 'ASC' },
    });
  }

  async findLevel(levelId: string): Promise<Level> {
    const level = await this.levelsRepository.findOne({
      where: { id: levelId },
      relations: ['venue'],
    });

    if (!level) {
      throw new NotFoundException(`Level with ID ${levelId} not found`);
    }

    return level;
  }

  async findLevelWithSpots(
    levelId: string,
    startAt?: Date,
    endAt?: Date,
  ): Promise<Level> {
    const level = await this.levelsRepository.findOne({
      where: { id: levelId },
      relations: ['venue', 'spots'],
      order: {
        spots: {
          spotNumber: 'ASC',
        },
      },
    });

    if (!level) {
      throw new NotFoundException(`Level with ID ${levelId} not found`);
    }

    // If date range provided, calculate date-specific availability for each spot
    if (startAt && endAt && level.spots) {
      // Get all spot IDs that have overlapping reservations
      const reservedSpotIds = await this.dataSource
        .createQueryBuilder(Reservation, 'r')
        .select('DISTINCT r.spot_id', 'spotId')
        .where('r.spot_id IN (:...spotIds)', {
          spotIds: level.spots.map((s) => s.id),
        })
        .andWhere('r.status IN (:...activeStatuses)', {
          activeStatuses: [
            ReservationStatus.PENDING,
            ReservationStatus.CONFIRMED,
            ReservationStatus.CHECKED_IN,
          ],
        })
        .andWhere('(r.start_at < :endAt AND r.end_at > :startAt)', {
          startAt,
          endAt,
        })
        .getRawMany<{ spotId: string }>();

      const reservedSpotIdSet = new Set(reservedSpotIds.map((r) => r.spotId));

      // Override spot status based on date-range availability
      // If a spot is reserved for the requested date range, mark it as reserved
      // Otherwise, mark it as available (even if currently reserved for a different time)
      for (const spot of level.spots) {
        if (reservedSpotIdSet.has(spot.id)) {
          spot.status = SpotStatus.RESERVED;
        } else {
          spot.status = SpotStatus.AVAILABLE;
        }
      }
    }

    return level;
  }

  async updateLevel(
    levelId: string,
    updateLevelDto: UpdateLevelDto,
    currentUserId: string,
  ): Promise<Level> {
    const level = await this.findLevel(levelId);

    // Handle Section Updates
    if (updateLevelDto.sections) {
      const existingSpots = await this.spotsRepository.find({ where: { levelId: level.id } });
      
      // Group existing spots by section
      const spotsBySection: { [key: string]: Spot[] } = {};
      existingSpots.forEach(spot => {
        const sectionName = spot.section || 'General';
        if (!spotsBySection[sectionName]) spotsBySection[sectionName] = [];
        spotsBySection[sectionName].push(spot);
      });

      let newTotalCapacity = 0;
      let newAvailableSpots = 0;

      // Process each section in the update
      for (const sectionDto of updateLevelDto.sections) {
        const sectionName = sectionDto.name;
        const targetCapacity = sectionDto.totalCapacity;
        const currentSpots = spotsBySection[sectionName] || [];
        const currentCount = currentSpots.length;

        newTotalCapacity += targetCapacity;

        if (targetCapacity > currentCount) {
          // Add spots
          const spotsToAdd = targetCapacity - currentCount;
          const newSpots: Partial<Spot>[] = [];
          for (let i = 1; i <= spotsToAdd; i++) {
            // Find next available number for this section
            // Simple approach: just append. Better approach: find gaps or max number.
            // We'll use max number + 1 based on existing spots in this section
            const maxNum = currentSpots.reduce((max, s) => {
              const parts = s.spotNumber.split('-');
              const num = parseInt(parts[parts.length - 1]);
              return isNaN(num) ? max : Math.max(max, num);
            }, 0);

            newSpots.push({
              spotNumber: `${sectionName}-${(maxNum + i).toString().padStart(3, '0')}`,
              levelId: level.id,
              status: SpotStatus.AVAILABLE,
              section: sectionName,
              vehicleType: sectionDto.vehicleType || 'Car',
            });
          }
          await this.spotsRepository.save(newSpots);
          newAvailableSpots += spotsToAdd; // Newly added spots are available
        } else if (targetCapacity < currentCount) {
          // Remove spots
          const spotsToRemoveCount = currentCount - targetCapacity;
          
          // Sort spots to remove: Available first, then Maintenance. 
          // We should NOT remove Occupied or Reserved spots if possible.
          const sortedSpots = currentSpots.sort((a, b) => {
            const score = (s: Spot) => {
              if (s.status === SpotStatus.AVAILABLE) return 0;
              if (s.status === SpotStatus.MAINTENANCE) return 1;
              return 2; // Occupied/Reserved
            };
            return score(a) - score(b);
          });

          const spotsToRemove = sortedSpots.slice(0, spotsToRemoveCount);
          
          // Check if we are about to delete occupied spots
          const hasOccupied = spotsToRemove.some(s => s.status === SpotStatus.OCCUPIED || s.status === SpotStatus.RESERVED);
          if (hasOccupied) {
            throw new BadRequestException(`Cannot reduce capacity for section ${sectionName}. Some spots are currently occupied or reserved.`);
          }

          await this.spotsRepository.remove(spotsToRemove);
          // We removed spots, so we don't add to available count here (they are gone)
        }
        
        // Count available spots for this section after changes
        // We need to re-fetch or calculate carefully. 
        // Simpler: Just count how many of the *remaining* spots are available.
        // But we just modified the DB.
        // Let's rely on the final aggregation.
      }

      // Handle removed sections (sections in DB but not in DTO)
      const updatedSectionNames = new Set(updateLevelDto.sections.map(s => s.name));
      for (const sectionName of Object.keys(spotsBySection)) {
        if (!updatedSectionNames.has(sectionName)) {
          const spotsToDelete = spotsBySection[sectionName];
          const hasOccupied = spotsToDelete.some(s => s.status === SpotStatus.OCCUPIED || s.status === SpotStatus.RESERVED);
          if (hasOccupied) {
             throw new BadRequestException(`Cannot remove section ${sectionName}. Some spots are currently occupied or reserved.`);
          }
          await this.spotsRepository.remove(spotsToDelete);
        }
      }

      // Recalculate total available spots for the level
      // We need to fetch fresh state because we did multiple operations
      const freshSpots = await this.spotsRepository.find({ where: { levelId: level.id } });
      level.totalCapacity = freshSpots.length;
      level.availableSpots = freshSpots.filter(s => s.status === SpotStatus.AVAILABLE).length;
      
      // Update level properties
      if (updateLevelDto.name) level.name = updateLevelDto.name;
      if (updateLevelDto.isCovered !== undefined) level.isCovered = updateLevelDto.isCovered;
      if (updateLevelDto.vehicleTypes) level.vehicleTypes = updateLevelDto.vehicleTypes;
      if (updateLevelDto.isActive !== undefined) level.isActive = updateLevelDto.isActive;

      const updatedLevel = await this.levelsRepository.save(level);
      
      await this.auditService.log(
        'UPDATE_LEVEL',
        `Updated level ${level.levelNumber} with section changes`,
        currentUserId,
        level.id,
        'Level'
      );
      
      return updatedLevel;

    } else if (
      updateLevelDto.totalCapacity &&
      updateLevelDto.totalCapacity > level.totalCapacity
    ) {
      // Legacy simple capacity update (only supports increase)
      const spotsToAdd = updateLevelDto.totalCapacity - level.totalCapacity;
      const existingSpotCount = level.totalCapacity;

      const newSpots: Partial<Spot>[] = [];
      for (let i = 1; i <= spotsToAdd; i++) {
        newSpots.push({
          spotNumber: `${level.levelNumber}-${(existingSpotCount + i).toString().padStart(3, '0')}`,
          levelId: level.id,
          status: SpotStatus.AVAILABLE,
        });
      }

      await this.spotsRepository.save(newSpots);

      // Update available spots count
      level.availableSpots += spotsToAdd;
      
      Object.assign(level, updateLevelDto);
      const updatedLevel = await this.levelsRepository.save(level);
      return updatedLevel;
    } else {
      // Simple update without capacity/section changes
      Object.assign(level, updateLevelDto);
      const updatedLevel = await this.levelsRepository.save(level);
      return updatedLevel;
    }
  }

  async removeLevel(id: string, currentUserId: string): Promise<void> {
    const level = await this.levelsRepository.findOne({ where: { id } });

    if (!level) {
      throw new NotFoundException(`Level with ID ${id} not found`);
    }

    await this.levelsRepository.remove(level);

    await this.auditService.log(
      'DELETE_LEVEL',
      `Deleted level ${level.levelNumber}`,
      currentUserId,
      id,
      'Level'
    );
  }

  async updateSpotStatus(
    spotId: string,
    status: SpotStatus,
    currentUserId: string,
  ): Promise<Spot> {
    const spot = await this.spotsRepository.findOne({ where: { id: spotId } });

    if (!spot) {
      throw new NotFoundException(`Spot with ID ${spotId} not found`);
    }

    spot.status = status;
    const updatedSpot = await this.spotsRepository.save(spot);

    // Recalculate available spots for the level
    const level = await this.levelsRepository.findOne({ where: { id: spot.levelId } });
    if (level) {
      const availableCount = await this.spotsRepository.count({
        where: {
          levelId: level.id,
          status: SpotStatus.AVAILABLE,
        },
      });
      level.availableSpots = availableCount;
      await this.levelsRepository.save(level);
    }

    return updatedSpot;
  }

  // ==================== HELPERS ====================

  private parseLocation(location: unknown): {
    latitude: number;
    longitude: number;
  } {
    // Handle GeoJSON format from TypeORM/PostGIS
    if (typeof location === 'object' && location !== null) {
      const geoJson = location as { type: string; coordinates: number[] };
      if (geoJson.type === 'Point' && Array.isArray(geoJson.coordinates)) {
        return {
          longitude: geoJson.coordinates[0],
          latitude: geoJson.coordinates[1],
        };
      }
    }

    // Parse PostGIS Point format: "POINT(lng lat)" or binary representation
    if (typeof location === 'string' && location.startsWith('POINT')) {
      const match = location.match(/POINT\(([^ ]+) ([^)]+)\)/);
      if (match) {
        return {
          longitude: parseFloat(match[1]),
          latitude: parseFloat(match[2]),
        };
      }
    }
    // Default fallback
    return { latitude: 0, longitude: 0 };
  }

  // ==================== CONFIGURATION OPERATIONS ====================

  async getVenueConfiguration(venueId: string): Promise<VenueConfiguration> {
    const venue = await this.venuesRepository.findOne({
      where: { id: venueId },
      relations: ['configuration'],
    });

    if (!venue) {
      throw new NotFoundException(`Venue with ID ${venueId} not found`);
    }

    if (!venue.configuration) {
      // Create default configuration if it doesn't exist
      const config = this.venueConfigurationRepository.create({
        venue: venue,
      });
      return this.venueConfigurationRepository.save(config);
    }

    return venue.configuration;
  }

  async updateVenueConfiguration(
    venueId: string,
    updateVenueConfigurationDto: UpdateVenueConfigurationDto,
    currentUserId: string,
  ): Promise<VenueConfiguration> {
    const config = await this.getVenueConfiguration(venueId);

    Object.assign(config, updateVenueConfigurationDto);

    const savedConfig = await this.venueConfigurationRepository.save(config);

    await this.auditService.log(
      'UPDATE_VENUE_CONFIG',
      `Updated configuration for venue ${venueId}`,
      currentUserId,
      config.id,
      'VenueConfiguration'
    );

    return savedConfig;
  }
}
