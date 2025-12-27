import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  action: string; // e.g., 'USER_LOGIN', 'UPDATE_VENUE', 'CHANGE_PASSWORD'

  @Column({ type: 'text', nullable: true })
  details: string;

  @Column({ nullable: true })
  resourceId: string; // ID of the affected resource (user_id, venue_id, etc.)

  @Column({ nullable: true })
  resourceType: string; // 'User', 'Venue', 'Reservation'

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'user_id', nullable: true })
  userId: string;

  @Column({ nullable: true })
  ipAddress: string;

  @Column({ type: 'jsonb', nullable: true })
  changes: { field: string; before: any; after: any }[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
