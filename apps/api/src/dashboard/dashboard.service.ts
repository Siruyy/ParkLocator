/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { User, UserRole } from '../users/entities/user.entity';
import { Venue } from '../venues/entities/venue.entity';
import { Level } from '../venues/entities/level.entity';
import {
  Reservation,
  ReservationStatus,
} from '../reservations/entities/reservation.entity';

@Injectable()
export class DashboardService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Venue)
    private venuesRepository: Repository<Venue>,
    @InjectRepository(Level)
    private levelsRepository: Repository<Level>,
    @InjectRepository(Reservation)
    private reservationsRepository: Repository<Reservation>,
  ) {}

  async getStats(user: any) {
    const isManager = user.role === UserRole.MANAGER;

    const venueId = user.venueId;

    // 1. User Stats
    const userWhere = isManager ? { venue: { id: venueId } } : {};
    const totalUsers = await this.usersRepository.count({ where: userWhere });

    const managerWhere = isManager ? { venue: { id: venueId } } : {};

    const managers = await this.usersRepository.count({
      where: {
        role: UserRole.MANAGER,
        ...managerWhere,
      },
    });
    const attendants = await this.usersRepository.count({
      where: {
        role: UserRole.ATTENDANT,
        ...managerWhere,
      },
    });

    // Mock active users for now as we don't track online status yet
    const activeNow = Math.floor(totalUsers * 0.2);

    // 2. Occupancy Stats
    const levelWhere = isManager ? { venue: { id: venueId } } : {};
    const levels = await this.levelsRepository.find({
      where: levelWhere,
      relations: isManager ? ['venue'] : [],
    });

    let totalCapacity = 0;
    let totalAvailable = 0;

    levels.forEach((level) => {
      totalCapacity += level.totalCapacity;
      totalAvailable += level.availableSpots;
    });

    const totalOccupied = totalCapacity - totalAvailable;
    const occupancyRate =
      totalCapacity > 0 ? Math.round((totalOccupied / totalCapacity) * 100) : 0;

    // 3. Reservation Stats
    const reservationWhere: any = {
      status: Between(ReservationStatus.PENDING, ReservationStatus.COMPLETED), // Just to have a base
    };

    if (isManager) {
      reservationWhere.venue = { id: venueId };
    }

    const activeReservations = await this.reservationsRepository.count({
      where: [
        {
          status: ReservationStatus.CONFIRMED,
          ...(isManager ? { venue: { id: venueId } } : {}),
        },
        {
          status: ReservationStatus.CHECKED_IN,
          ...(isManager ? { venue: { id: venueId } } : {}),
        },
      ],
    });

    // 4. Revenue Stats (Today vs Yesterday)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const todaysReservations = await this.reservationsRepository.find({
      where: {
        createdAt: Between(today, tomorrow),
        status: ReservationStatus.CONFIRMED,
        ...(isManager ? { venue: { id: venueId } } : {}),
      },
    });

    const yesterdaysReservations = await this.reservationsRepository.find({
      where: {
        createdAt: Between(yesterday, today),
        status: ReservationStatus.CONFIRMED,
        ...(isManager ? { venue: { id: venueId } } : {}),
      },
    });

    const todaysRevenue = todaysReservations.reduce(
      (sum, res) => sum + Number(res.amount),
      0,
    );
    const yesterdaysRevenue = yesterdaysReservations.reduce(
      (sum, res) => sum + Number(res.amount),
      0,
    );

    const revenueTrend =
      yesterdaysRevenue === 0
        ? todaysRevenue > 0
          ? 100
          : 0
        : Math.round(
            ((todaysRevenue - yesterdaysRevenue) / yesterdaysRevenue) * 100,
          );

    // Occupancy Trend (using Check-ins as proxy)
    const todaysCheckins = await this.reservationsRepository.count({
      where: {
        startAt: Between(today, tomorrow),
        ...(isManager ? { venue: { id: venueId } } : {}),
      },
    });

    const yesterdaysCheckins = await this.reservationsRepository.count({
      where: {
        startAt: Between(yesterday, today),
        ...(isManager ? { venue: { id: venueId } } : {}),
      },
    });

    const occupancyTrend =
      yesterdaysCheckins === 0
        ? todaysCheckins > 0
          ? 100
          : 0
        : Math.round(
            ((todaysCheckins - yesterdaysCheckins) / yesterdaysCheckins) * 100,
          );

    // 5. Recent Activities
    const recentReservations = await this.reservationsRepository.find({
      where: isManager ? { venue: { id: venueId } } : {},
      relations: ['user', 'venue'],
      order: { createdAt: 'DESC' },
      take: 5,
    });

    const recentActivities = recentReservations.map((res) => ({
      title: `Reservation ${res.status}`,
      time: res.createdAt, // Frontend will format this
      icon: 'confirmation_number',
      iconBg: 'bg-green-50 dark:bg-green-900/20',
      iconColor: 'text-green-600 dark:text-green-400',
      details: `${res.user?.email || 'Unknown User'} • ${res.venue?.name || 'Unknown Venue'}`,
    }));

    return {
      userStats: {
        totalUsers,
        activeNow,
        managers,
        attendants,
      },
      occupancyRate,
      totalOccupied,
      totalCapacity,
      occupancyData: [
        {
          label: 'Occupied',
          value: occupancyRate,
          color: '#34d399',
          icon: 'pi pi-car',
        },
        {
          label: 'Available',
          value: 100 - occupancyRate,
          color: '#e5e7eb',
          icon: 'pi pi-check-circle',
        },
      ],
      activeReservations,
      todaysRevenue,
      revenueTrend,
      occupancyTrend,
      recentActivities,
    };
  }
}
