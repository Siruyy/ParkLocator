import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Level } from './level.entity';

export enum SpotStatus {
  AVAILABLE = 'available',
  OCCUPIED = 'occupied',
  RESERVED = 'reserved',
  MAINTENANCE = 'maintenance',
}

@Entity('spots')
export class Spot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'spot_number' })
  spotNumber: string;

  @Column({
    type: 'enum',
    enum: SpotStatus,
    default: SpotStatus.AVAILABLE,
  })
  status: SpotStatus;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ nullable: true })
  section: string;

  @Column({ name: 'vehicle_type', default: 'Car' })
  vehicleType: string;

  @Column({ name: 'level_id' })
  levelId: string;

  @ManyToOne(() => Level, (level) => level.spots, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'level_id' })
  level: Level;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
