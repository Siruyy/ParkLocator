import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, LessThan, In } from 'typeorm';
import { Reservation, ReservationStatus, ReservationType } from './entities/reservation.entity';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { Spot, SpotStatus } from '../venues/entities/spot.entity';
import { Level } from '../venues/entities/level.entity';
import { Venue } from '../venues/entities/venue.entity';
import { VenueConfiguration } from '../venues/entities/venue-configuration.entity';
import { v4 as uuidv4 } from 'uuid';
import { EventsGateway } from '../events/events.gateway';

import { User, UserRole } from '../users/entities/user.entity';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class ReservationsService {
  constructor(
    @InjectRepository(Reservation)
    private reservationsRepository: Repository<Reservation>,
    @InjectRepository(Spot)
    private spotsRepository: Repository<Spot>,
    @InjectRepository(Level)
    private levelsRepository: Repository<Level>,
    @InjectRepository(Venue)
    private venuesRepository: Repository<Venue>,
    @InjectRepository(VenueConfiguration)
    private venueConfigurationRepository: Repository<VenueConfiguration>,
    private dataSource: DataSource,
    private eventsGateway: EventsGateway,
    private auditService: AuditService,
  ) {}

  /**
   * Create a reservation with transactional spot locking to prevent double-booking
   */
  async create(
    userId: string,
    createReservationDto: CreateReservationDto,
  ): Promise<Reservation> {
    const {
      venueId,
      levelId,
      spotId,
      vehicleId,
      durationHours = 1,
      startAt,
      endAt,
    } = createReservationDto;

    // Use a transaction to ensure atomicity
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('SERIALIZABLE');

    try {
      // Lock the spot row for update to prevent concurrent reservations
      const spot = await queryRunner.manager.findOne(Spot, {
        where: { id: spotId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!spot) {
        throw new NotFoundException(`Spot with ID ${spotId} not found`);
      }

      if (spot.levelId !== levelId) {
        throw new BadRequestException(
          'Spot does not belong to the specified level',
        );
      }

      // Verify venue and level exist
      const venue = await queryRunner.manager.findOne(Venue, {
        where: { id: venueId },
        relations: ['configuration'],
      });

      if (!venue) {
        throw new NotFoundException(`Venue with ID ${venueId} not found`);
      }

      const level = await queryRunner.manager.findOne(Level, {
        where: { id: levelId },
      });

      if (!level || level.venueId !== venueId) {
        throw new BadRequestException(
          'Level does not belong to the specified venue',
        );
      }

      // Fetch venue configuration first (needed for baseDuration calculation)
      let venueConfig = venue.configuration;

      if (!venueConfig) {
        // Create default configuration in memory if it doesn't exist
        venueConfig = this.venueConfigurationRepository.create({
          venueId: venueId,
          reservationFee: 50, // Default reservation fee
          baseDuration: 2, // Default 2 hours base duration
          baseRate: 0,
          succeedingHourRate: 20,
          overnightFlatRate: 300,
          motorcycleFlatRate: 30,
          weekendSurcharge: 0,
        });
      }

      // Get base duration from config (default 2 hours if not set)
      const baseDurationHours = venueConfig.baseDuration || 2;

      // Calculate reservation times
      // End time is always Start + Base Duration
      // After base duration, succeeding hour rate applies (tracked by sensors, paid on exit)
      let reservationStartAt: Date;
      let reservationEndAt: Date;
      let reservationType: ReservationType;

      if (startAt) {
        // "Book for Later" - use provided start date
        reservationStartAt = new Date(startAt as string);
        reservationType = ReservationType.SCHEDULED;
      } else {
        // "Book Now" - start immediately
        reservationStartAt = new Date();
        reservationType = ReservationType.IMMEDIATE;
      }
      
      // End time = Start + Base Duration (succeeding hours tracked separately)
      reservationEndAt = new Date(
        reservationStartAt.getTime() + baseDurationHours * 60 * 60 * 1000,
      );

      // Check for overlapping reservations on this spot for the requested time range
      const overlappingReservation = await queryRunner.manager
        .createQueryBuilder(Reservation, 'r')
        .where('r.spot_id = :spotId', { spotId })
        .andWhere('r.status IN (:...activeStatuses)', {
          activeStatuses: [
            ReservationStatus.PENDING,
            ReservationStatus.CONFIRMED,
            ReservationStatus.CHECKED_IN,
          ],
        })
        .andWhere(
          // Check for time overlap: new reservation overlaps if it starts before existing ends AND ends after existing starts
          '(r.start_at < :endAt AND r.end_at > :startAt)',
          { startAt: reservationStartAt, endAt: reservationEndAt },
        )
        .getOne();

      if (overlappingReservation) {
        throw new ConflictException(
          `Spot ${spot.spotNumber} is already reserved for the selected time period`,
        );
      }

      // Calculate price - For reservations, only charge the reservation fee.
      // The actual parking fees (baseRate, succeedingHourRate) will be calculated
      // by sensors when the user checks out after the base duration.
      const amount = Number(venueConfig.reservationFee) || 50;

      // Calculate arrival window expiry (time user has to arrive before reservation expires)
      const arrivalWindow = venueConfig.maxReservationHold || 45;
      const expiresAt = new Date(
        reservationStartAt.getTime() + arrivalWindow * 60 * 1000,
      );

      // Generate unique QR code
      const qrCode = uuidv4();

      // Create reservation
      const reservation = queryRunner.manager.create(Reservation, {
        userId,
        venueId,
        levelId,
        spotId,
        vehicleId,
        status: ReservationStatus.CONFIRMED, // Skip pending for now, assume payment is instant
        amount,
        durationHours: baseDurationHours,
        startAt: reservationStartAt,
        endAt: reservationEndAt,
        arrivalWindowMinutes: arrivalWindow,
        expiresAt,
        qrCode,
        type: reservationType,
      });

      await queryRunner.manager.save(reservation);

      // For "Book Now" only: Update spot status to reserved immediately
      // For "Book for Later": spot status remains available until the reservation time
      const isBookNow =
        !startAt ||
        new Date(startAt as string).getTime() - Date.now() < 60 * 60 * 1000; // within 1 hour
      if (isBookNow) {
        spot.status = SpotStatus.RESERVED;
        await queryRunner.manager.save(spot);

        // Update level available spots count only for immediate bookings
        level.availableSpots = Math.max(0, level.availableSpots - 1);
        await queryRunner.manager.save(level);

        // Emit real-time update
        this.eventsGateway.emitLevelUpdate(level.id, {
          availableSpots: level.availableSpots,
          totalCapacity: level.totalCapacity,
        });
      }

      await queryRunner.commitTransaction();

      // Return the complete reservation with relations
      return this.findOne(reservation.id);
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Find all reservations for a user
   */
  async findAllByUser(userId: string): Promise<Reservation[]> {
    return this.reservationsRepository.find({
      where: { userId },
      relations: ['venue', 'level', 'spot'],
      order: { createdAt: 'DESC' },
    });
  }

  async findAllForAdmin(user: User): Promise<Reservation[]> {
    const where: any = {};

    if (user.role === UserRole.MANAGER) {
      if (!user.venueId) {
        return [];
      }
      where.venueId = user.venueId;
    }

    return this.reservationsRepository.find({
      where,
      relations: ['user', 'venue', 'level', 'spot', 'vehicle'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Find active reservations for a user
   */
  async findActiveByUser(userId: string): Promise<Reservation[]> {
    return this.reservationsRepository.find({
      where: {
        userId,
        status: In([
          ReservationStatus.PENDING,
          ReservationStatus.CONFIRMED,
          ReservationStatus.CHECKED_IN,
        ]),
      },
      relations: ['venue', 'level', 'spot'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Find a single reservation by ID
   */
  async findOne(id: string): Promise<Reservation> {
    const reservation = await this.reservationsRepository.findOne({
      where: { id },
      relations: ['venue', 'level', 'spot', 'user'],
    });

    if (!reservation) {
      throw new NotFoundException(`Reservation with ID ${id} not found`);
    }

    return reservation;
  }

  /**
   * Find reservation by QR code
   */
  async findByQrCode(qrCode: string): Promise<Reservation> {
    const reservation = await this.reservationsRepository.findOne({
      where: { qrCode },
      relations: ['venue', 'level', 'spot', 'user'],
    });

    if (!reservation) {
      throw new NotFoundException('Invalid QR code');
    }

    return reservation;
  }

  /**
   * Cancel a reservation and release the spot
   */
  async cancel(id: string, userId: string): Promise<Reservation> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const reservation = await queryRunner.manager.findOne(Reservation, {
        where: { id, userId },
        relations: ['spot', 'level'],
      });

      if (!reservation) {
        throw new NotFoundException(`Reservation with ID ${id} not found`);
      }

      if (
        reservation.status !== ReservationStatus.PENDING &&
        reservation.status !== ReservationStatus.CONFIRMED
      ) {
        throw new BadRequestException(
          `Cannot cancel reservation with status: ${reservation.status}`,
        );
      }

      // Update reservation status
      reservation.status = ReservationStatus.CANCELLED;
      await queryRunner.manager.save(reservation);

      // Release the spot
      const spot = await queryRunner.manager.findOne(Spot, {
        where: { id: reservation.spotId },
      });

      if (spot) {
        spot.status = SpotStatus.AVAILABLE;
        await queryRunner.manager.save(spot);
      }

      // Update level available spots count
      const level = await queryRunner.manager.findOne(Level, {
        where: { id: reservation.levelId },
      });

      if (level) {
        level.availableSpots += 1;
        await queryRunner.manager.save(level);

        // Emit real-time update
        this.eventsGateway.emitLevelUpdate(level.id, {
          availableSpots: level.availableSpots,
          totalCapacity: level.totalCapacity,
        });
      }

      await queryRunner.commitTransaction();

      await this.auditService.log(
        'CANCEL_RESERVATION',
        `Cancelled reservation ${reservation.qrCode}`,
        userId,
        id,
        'Reservation'
      );

      return this.findOne(id);
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Check in to a reservation (validate QR code at entry)
   */
  async checkIn(qrCode: string): Promise<Reservation> {
    const reservation = await this.findByQrCode(qrCode);

    if (reservation.status !== ReservationStatus.CONFIRMED) {
      throw new BadRequestException(
        `Cannot check in. Reservation status: ${reservation.status}`,
      );
    }

    if (new Date() > reservation.expiresAt) {
      // Mark as expired if past the arrival window
      reservation.status = ReservationStatus.EXPIRED;
      await this.reservationsRepository.save(reservation);
      throw new BadRequestException('Reservation has expired');
    }

    reservation.status = ReservationStatus.CHECKED_IN;
    reservation.checkedInAt = new Date();
    await this.reservationsRepository.save(reservation);

    return this.findOne(reservation.id);
  }

  /**
   * Check out from a reservation (validate QR code at exit)
   */
  async checkOut(qrCode: string): Promise<Reservation> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const reservation = await queryRunner.manager.findOne(Reservation, {
        where: { qrCode },
        relations: ['spot', 'level'],
      });

      if (!reservation) {
        throw new NotFoundException('Invalid QR code');
      }

      if (reservation.status !== ReservationStatus.CHECKED_IN) {
        throw new BadRequestException(
          `Cannot check out. Reservation status: ${reservation.status}`,
        );
      }

      // Update reservation
      reservation.status = ReservationStatus.COMPLETED;
      reservation.checkedOutAt = new Date();
      await queryRunner.manager.save(reservation);

      // Release the spot
      const spot = await queryRunner.manager.findOne(Spot, {
        where: { id: reservation.spotId },
      });

      if (spot) {
        spot.status = SpotStatus.AVAILABLE;
        await queryRunner.manager.save(spot);
      }

      // Update level available spots count
      const level = await queryRunner.manager.findOne(Level, {
        where: { id: reservation.levelId },
      });

      if (level) {
        level.availableSpots += 1;
        await queryRunner.manager.save(level);

        // Emit real-time update
        this.eventsGateway.emitLevelUpdate(level.id, {
          availableSpots: level.availableSpots,
          totalCapacity: level.totalCapacity,
        });
      }

      await queryRunner.commitTransaction();

      return this.findOne(reservation.id);
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Expire reservations that have passed their arrival window
   * This should be called by a scheduled job
   */
  async expireOverdueReservations(): Promise<number> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const now = new Date();

      // Find all confirmed reservations past their expiry time
      const expiredReservations = await queryRunner.manager.find(Reservation, {
        where: {
          status: ReservationStatus.CONFIRMED,
          expiresAt: LessThan(now),
        },
        relations: ['spot', 'level'],
      });

      for (const reservation of expiredReservations) {
        // Update reservation status
        reservation.status = ReservationStatus.EXPIRED;
        await queryRunner.manager.save(reservation);

        // Release the spot
        const spot = await queryRunner.manager.findOne(Spot, {
          where: { id: reservation.spotId },
        });

        if (spot) {
          spot.status = SpotStatus.AVAILABLE;
          await queryRunner.manager.save(spot);
        }

        // Update level available spots count
        const level = await queryRunner.manager.findOne(Level, {
          where: { id: reservation.levelId },
        });

        if (level) {
          level.availableSpots += 1;
          await queryRunner.manager.save(level);
        }
      }

      await queryRunner.commitTransaction();

      return expiredReservations.length;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  private calculateTotalPrice(
    config: VenueConfiguration,
    durationHours: number,
    vehicleType: string,
    startDate: Date,
  ): number {
    // Apply Entry Grace Period (deduct from duration)
    const gracePeriodHours = config.entryGracePeriod / 60;
    const billableDuration = Math.max(0, durationHours - gracePeriodHours);

    if (billableDuration === 0) {
      return 0;
    }

    // Check for multi-day booking (over 24 hours)
    if (billableDuration > 24) {
      const days = Math.ceil(billableDuration / 24);
      return days * Number(config.overnightFlatRate);
    }

    // Single day booking
    
    // Check for motorcycle flat rate
    if (
      vehicleType === 'Motorcycle' &&
      config.isMotorcycleFlatRateActive
    ) {
      return Number(config.motorcycleFlatRate);
    }

    // Standard Rate Calculation
    let price = Number(config.baseRate);
    const baseDuration = config.baseDuration || 1; // Default to 1 hour if not set
    
    if (billableDuration > baseDuration) {
      const succeedingHours = Math.ceil(billableDuration - baseDuration);
      price += succeedingHours * Number(config.succeedingHourRate);
    }

    // Weekend Surcharge
    if (config.isWeekendSurchargeActive) {
      const day = startDate.getDay();
      // 0 is Sunday, 6 is Saturday
      if (day === 0 || day === 6) {
        price += Number(config.weekendSurcharge);
      }
    }

    // Add Reservation Fee
    if (config.reservationFee) {
      price += Number(config.reservationFee);
    }

    return price;
  }
}
