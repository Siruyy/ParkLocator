import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Venue } from '../../venues/entities/venue.entity';

export enum UserRole {
  SUPER_ADMIN = 'super_admin',
  DRIVER = 'driver',
  MANAGER = 'manager',
  ATTENDANT = 'attendant',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  email: string;

  @Column()
  password: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.DRIVER,
  })
  role: UserRole;

  @Column({ name: 'venue_id', nullable: true })
  venueId: string | null;

  @ManyToOne(() => Venue, (venue) => venue.users)
  @JoinColumn({ name: 'venue_id' })
  venue: Venue | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
