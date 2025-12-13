import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Venue, Level, Spot, SpotStatus } from './entities';
import {
  CreateVenueDto,
  UpdateVenueDto,
  NearbyVenueDto,
  CreateLevelDto,
  UpdateLevelDto,
  LevelAvailabilityDto,
} from './dto';

@Injectable()
export class VenuesService {
  constructor(
    @InjectRepository(Venue)
    private venuesRepository: Repository<Venue>,
    @InjectRepository(Level)
    private levelsRepository: Repository<Level>,
    @InjectRepository(Spot)
    private spotsRepository: Repository<Spot>,
    private dataSource: DataSource,
  ) {}

  // ==================== VENUE OPERATIONS ====================

  async create(createVenueDto: CreateVenueDto): Promise<Venue> {
    const { latitude, longitude, name, address, description, imageUrl } =
      createVenueDto;

    // Use raw query to insert with PostGIS geography
    const result = await this.dataSource.query(
      `INSERT INTO venues (name, address, location, description, image_url)
       VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5, $6)
       RETURNING *`,
      [
        name,
        address,
        longitude,
        latitude,
        description || null,
        imageUrl || null,
      ],
    );

    return this.findOne(result[0].id);
  }

  async findAll(): Promise<Venue[]> {
    return this.venuesRepository.find({
      where: { isActive: true },
      relations: ['levels'],
    });
  }

  async findOne(id: string): Promise<Venue> {
    const venue = await this.venuesRepository.findOne({
      where: { id },
      relations: ['levels'],
    });

    if (!venue) {
      throw new NotFoundException(`Venue with ID ${id} not found`);
    }

    return venue;
  }

  async update(id: string, updateVenueDto: UpdateVenueDto): Promise<Venue> {
    const venue = await this.findOne(id);

    const { latitude, longitude, ...rest } = updateVenueDto;

    // Update location if coordinates provided
    if (latitude !== undefined && longitude !== undefined) {
      await this.dataSource.query(
        `UPDATE venues SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
        [longitude, latitude, id],
      );
    }

    // Update other fields
    Object.assign(venue, rest);
    return this.venuesRepository.save(venue);
  }

  async remove(id: string): Promise<void> {
    const venue = await this.findOne(id);
    await this.venuesRepository.remove(venue);
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

      // Parse coordinates from location
      const coords = this.parseLocation(venue.location);

      return {
        id: venue.id,
        name: venue.name,
        address: venue.address,
        latitude: coords.latitude,
        longitude: coords.longitude,
        description: venue.description,
        imageUrl: venue.imageUrl,
        isActive: venue.isActive,
        createdAt: venue.createdAt.toISOString(),
        updatedAt: venue.updatedAt.toISOString(),
        distance: Math.round(parseFloat(raw.distance)),
        levelsCount: venue.levels.length,
        totalCapacity,
        availableSpots,
      };
    });
  }

  // ==================== AVAILABILITY ====================

  async getAvailability(venueId: string): Promise<LevelAvailabilityDto[]> {
    const venue = await this.findOne(venueId);

    return venue.levels
      .filter((level) => level.isActive)
      .map((level) => ({
        id: level.id,
        levelNumber: level.levelNumber,
        name: level.name,
        totalCapacity: level.totalCapacity,
        availableSpots: level.availableSpots,
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

  // ==================== LEVEL OPERATIONS ====================

  async createLevel(
    venueId: string,
    createLevelDto: CreateLevelDto,
  ): Promise<Level> {
    const venue = await this.findOne(venueId);

    const level = this.levelsRepository.create({
      ...createLevelDto,
      venueId: venue.id,
      availableSpots: createLevelDto.totalCapacity, // Initially all spots are available
    });

    const savedLevel = await this.levelsRepository.save(level);

    // Create individual spots for the level
    const spots: Partial<Spot>[] = [];
    for (let i = 1; i <= createLevelDto.totalCapacity; i++) {
      spots.push({
        spotNumber: `${level.levelNumber}-${i.toString().padStart(3, '0')}`,
        levelId: savedLevel.id,
        status: SpotStatus.AVAILABLE,
      });
    }

    await this.spotsRepository.save(spots);

    return savedLevel;
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

  async updateLevel(
    levelId: string,
    updateLevelDto: UpdateLevelDto,
  ): Promise<Level> {
    const level = await this.findLevel(levelId);

    // If capacity is being increased, add new spots
    if (
      updateLevelDto.totalCapacity &&
      updateLevelDto.totalCapacity > level.totalCapacity
    ) {
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
    }

    Object.assign(level, updateLevelDto);
    return this.levelsRepository.save(level);
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
}
