import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Venue } from './venue.entity';
import { Spot } from './spot.entity';

@Entity('levels')
export class Level {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'level_number' })
  levelNumber: number;

  @Column()
  name: string;

  @Column({ name: 'total_capacity' })
  totalCapacity: number;

  @Column({ name: 'available_spots', default: 0 })
  availableSpots: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'is_covered', default: true })
  isCovered: boolean;

  @Column('simple-array', { name: 'vehicle_types', default: 'Car' })
  vehicleTypes: string[];

  @Column({ name: 'venue_id' })
  venueId: string;

  @ManyToOne(() => Venue, (venue) => venue.levels, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'venue_id' })
  venue: Venue;

  @OneToMany(() => Spot, (spot) => spot.level, { cascade: true })
  spots: Spot[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
