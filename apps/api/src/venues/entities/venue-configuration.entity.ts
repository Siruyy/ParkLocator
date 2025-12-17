import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Venue } from './venue.entity';

@Entity('venue_configurations')
export class VenueConfiguration {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'venue_id' })
  venueId: string;

  @OneToOne(() => Venue, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'venue_id' })
  venue: Venue;

  // Standard Rates
  @Column({ name: 'reservation_fee', type: 'decimal', precision: 10, scale: 2, default: 0.00 })
  reservationFee: number;

  @Column({ name: 'base_rate', type: 'decimal', precision: 10, scale: 2, default: 40.00 })
  baseRate: number;

  @Column({ name: 'base_duration', default: 1 })
  baseDuration: number; // hours

  @Column({ name: 'succeeding_hour_rate', type: 'decimal', precision: 10, scale: 2, default: 20.00 })
  succeedingHourRate: number;

  // Weekend Surcharge
  @Column({ name: 'weekend_surcharge', type: 'decimal', precision: 10, scale: 2, default: 0.00 })
  weekendSurcharge: number;

  @Column({ name: 'is_weekend_surcharge_active', default: false })
  isWeekendSurchargeActive: boolean;

  // Motorcycle Flat Rate
  @Column({ name: 'motorcycle_flat_rate', type: 'decimal', precision: 10, scale: 2, default: 30.00 })
  motorcycleFlatRate: number;

  @Column({ name: 'is_motorcycle_flat_rate_active', default: false })
  isMotorcycleFlatRateActive: boolean;

  // Overnight Parking
  @Column({ name: 'overnight_flat_rate', type: 'decimal', precision: 10, scale: 2, default: 300.00 })
  overnightFlatRate: number;

  @Column({ name: 'overnight_start_hour', default: '22:00' })
  overnightStartHour: string;

  @Column({ name: 'overnight_end_hour', default: '06:00' })
  overnightEndHour: string;

  @Column({ name: 'is_overnight_parking_active', default: false })
  isOvernightParkingActive: boolean;

  // Limits & Grace Periods
  @Column({ name: 'entry_grace_period', default: 15 })
  entryGracePeriod: number; // minutes

  @Column({ name: 'exit_grace_period', default: 10 })
  exitGracePeriod: number; // minutes

  @Column({ name: 'max_reservation_hold', default: 30 })
  maxReservationHold: number; // minutes

  // Penalties
  @Column({ name: 'lost_ticket_penalty', type: 'decimal', precision: 10, scale: 2, default: 500.00 })
  lostTicketPenalty: number;

  @Column({ name: 'illegal_parking_penalty', type: 'decimal', precision: 10, scale: 2, default: 1000.00 })
  illegalParkingPenalty: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
