import { Exclude } from 'class-transformer';
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Venue } from '../../venues/entities/venue.entity';
import { Vehicle } from './vehicle.entity';

export enum UserRole {
  SUPER_ADMIN = 'super_admin',
  DRIVER = 'driver',
  MANAGER = 'manager',
  ATTENDANT = 'attendant',
}

export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  LOCKED = 'locked',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  email: string;

  @Column()
  @Exclude()
  password: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.DRIVER,
  })
  role: UserRole;

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.ACTIVE,
  })
  status: UserStatus;

  @Column({ name: 'venue_id', nullable: true })
  venueId: string | null;

  @Column({ name: 'employee_id', nullable: true, type: 'varchar' })
  employeeId: string | null;

  @Column({ nullable: true, type: 'varchar' })
  department: string | null;

  @Column({ nullable: true, type: 'varchar' })
  location: string | null;

  @Column({ name: 'avatar_url', nullable: true, type: 'varchar' })
  avatarUrl: string | null;

  @ManyToOne(() => Venue, (venue) => venue.users, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'venue_id' })
  venue: Venue | null;

  @OneToMany(() => Vehicle, (vehicle) => vehicle.user)
  vehicles: Vehicle[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
