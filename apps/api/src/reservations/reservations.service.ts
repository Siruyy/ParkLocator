import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, LessThan, In } from 'typeorm';
import { Reservation, ReservationStatus } from './entities/reservation.entity';
import { CreateReservationDto } from './dto/create-reservation.dto';
import { Spot, SpotStatus } from '../venues/entities/spot.entity';
import { Level } from '../venues/entities/level.entity';
import { Venue } from '../venues/entities/venue.entity';
import { v4 as uuidv4 } from 'uuid';

const PRICE_PER_HOUR = 40; // Base price per hour in PHP
const ARRIVAL_WINDOW_MINUTES = 60; // 1 hour arrival window

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
    private dataSource: DataSource,
  ) {}

  /**
   * Create a reservation with transactional spot locking to prevent double-booking
   */
  async create(
    userId: string,
    createReservationDto: CreateReservationDto,
  ): Promise<Reservation> {
    const { venueId, levelId, spotId, durationHours = 1 } = createReservationDto;

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

      if (spot.status !== SpotStatus.AVAILABLE) {
        throw new ConflictException(
          `Spot ${spot.spotNumber} is not available. Current status: ${spot.status}`,
        );
      }

      if (spot.levelId !== levelId) {
        throw new BadRequestException('Spot does not belong to the specified level');
      }

      // Verify venue and level exist
      const venue = await queryRunner.manager.findOne(Venue, {
        where: { id: venueId },
      });

      if (!venue) {
        throw new NotFoundException(`Venue with ID ${venueId} not found`);
      }

      const level = await queryRunner.manager.findOne(Level, {
        where: { id: levelId },
      });

      if (!level || level.venueId !== venueId) {
        throw new BadRequestException('Level does not belong to the specified venue');
      }

      // Calculate price and expiry
      const amount = PRICE_PER_HOUR * durationHours;
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + ARRIVAL_WINDOW_MINUTES);

      // Generate unique QR code
      const qrCode = uuidv4();

      // Create reservation
      const reservation = queryRunner.manager.create(Reservation, {
        userId,
        venueId,
        levelId,
        spotId,
        status: ReservationStatus.CONFIRMED, // Skip pending for now, assume payment is instant
        amount,
        durationHours,
        arrivalWindowMinutes: ARRIVAL_WINDOW_MINUTES,
        expiresAt,
        qrCode,
      });

      await queryRunner.manager.save(reservation);

      // Update spot status to reserved
      spot.status = SpotStatus.RESERVED;
      await queryRunner.manager.save(spot);

      // Update level available spots count
      level.availableSpots = Math.max(0, level.availableSpots - 1);
      await queryRunner.manager.save(level);

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
      }

      await queryRunner.commitTransaction();

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
}
