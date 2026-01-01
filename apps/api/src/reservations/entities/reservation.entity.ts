import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Vehicle } from '../../users/entities/vehicle.entity';
import { Spot } from '../../venues/entities/spot.entity';
import { Level } from '../../venues/entities/level.entity';
import { Venue } from '../../venues/entities/venue.entity';

export enum ReservationStatus {
  PENDING = 'pending', // Created but not yet paid
  CONFIRMED = 'confirmed', // Paid and valid
  CHECKED_IN = 'checked_in', // User has arrived
  COMPLETED = 'completed', // User has exited
  CANCELLED = 'cancelled', // User cancelled
  EXPIRED = 'expired', // Arrival window expired
  NO_SHOW = 'no_show', // Paid but didn't arrive
}

export enum ReservationType {
  IMMEDIATE = 'immediate', // Book Now
  SCHEDULED = 'scheduled', // Book for Later
}

@Entity('reservations')
export class Reservation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: ReservationType,
    default: ReservationType.IMMEDIATE,
  })
  type: ReservationType;

  @Column({ name: 'user_id' })
  @Index()
  userId: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'vehicle_id', nullable: true })
  @Index()
  vehicleId: string | null;

  @ManyToOne(() => Vehicle, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'vehicle_id' })
  vehicle: Vehicle | null;

  @Column({ name: 'venue_id' })
  @Index()
  venueId: string;

  @ManyToOne(() => Venue, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'venue_id' })
  venue: Venue;

  @Column({ name: 'level_id' })
  @Index()
  levelId: string;

  @ManyToOne(() => Level, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'level_id' })
  level: Level;

  @Column({ name: 'spot_id' })
  @Index()
  spotId: string;

  @ManyToOne(() => Spot, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'spot_id' })
  spot: Spot;

  @Column({
    type: 'enum',
    enum: ReservationStatus,
    default: ReservationStatus.PENDING,
  })
  @Index()
  status: ReservationStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ name: 'duration_hours', type: 'int', default: 1 })
  durationHours: number;

  @Column({ name: 'start_at', type: 'timestamp' })
  @Index()
  startAt: Date;

  @Column({ name: 'end_at', type: 'timestamp' })
  @Index()
  endAt: Date;

  @Column({ name: 'arrival_window_minutes', type: 'int', default: 60 })
  arrivalWindowMinutes: number;

  @Column({ name: 'expires_at', type: 'timestamp' })
  @Index()
  expiresAt: Date;

  @Column({ name: 'checked_in_at', type: 'timestamp', nullable: true })
  checkedInAt: Date | null;

  @Column({ name: 'checked_out_at', type: 'timestamp', nullable: true })
  checkedOutAt: Date | null;

  @Column({
    name: 'actual_duration_hours',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  actualDurationHours: number | null;

  @Column({
    name: 'final_amount',
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  finalAmount: number | null;

  @Column({ name: 'qr_code', type: 'varchar', nullable: true, unique: true })
  qrCode: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
