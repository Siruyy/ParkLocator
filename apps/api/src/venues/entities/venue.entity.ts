import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  OneToMany,
  OneToOne,
  Index,
  AfterLoad,
} from 'typeorm';
import { Level } from './level.entity';
import { VenueConfiguration } from './venue-configuration.entity';
import { User } from '../../users/entities/user.entity';

@Entity('venues')
export class Venue {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  address: string;

  @Column({ type: 'geography', spatialFeatureType: 'Point', srid: 4326 })
  @Index({ spatial: true })
  location: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'supports_real_time_booking', default: true })
  supportsRealTimeBooking: boolean;

  @Column({ name: 'supports_future_booking', default: false })
  supportsFutureBooking: boolean;

  @Column({ name: 'require_vehicle_details', default: true })
  requireVehicleDetails: boolean;

  @Column({ name: 'has_covered_parking', default: false })
  hasCoveredParking: boolean;

  @Column({ name: 'has_cctv', default: false })
  hasCCTV: boolean;

  @Column({ name: 'image_url', type: 'varchar', nullable: true })
  imageUrl: string | null;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @OneToMany(() => Level, (level) => level.venue, { cascade: true })
  levels: Level[];

  @OneToMany(() => User, (user) => user.venue)
  users: User[];

  @OneToOne(() => VenueConfiguration, (config) => config.venue, { cascade: true })
  configuration: VenueConfiguration;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at' })
  deletedAt: Date;

  // Virtual properties for easier frontend consumption
  latitude: number | null = null;
  longitude: number | null = null;

  @AfterLoad()
  _convertLocation() {
    if (!this.location) return;

    // Handle GeoJSON object (TypeORM default for geography)
    if (typeof this.location === 'object' && (this.location as any).type === 'Point') {
      const coords = (this.location as any).coordinates;
      if (Array.isArray(coords) && coords.length === 2) {
        this.longitude = coords[0];
        this.latitude = coords[1];
      }
    }
    // Handle WKT string (e.g. "POINT(-122.4 37.7)")
    else if (typeof this.location === 'string' && this.location.startsWith('POINT')) {
      const match = this.location.match(/POINT\(([^ ]+) ([^)]+)\)/);
      if (match) {
        this.longitude = parseFloat(match[1]);
        this.latitude = parseFloat(match[2]);
      }
    }
  }

  toJSON() {
    // Ensure _convertLocation is called before serialization
    this._convertLocation();
    return {
      id: this.id,
      name: this.name,
      address: this.address,
      location: this.location,
      isActive: this.isActive,
      supportsRealTimeBooking: this.supportsRealTimeBooking,
      supportsFutureBooking: this.supportsFutureBooking,
      requireVehicleDetails: this.requireVehicleDetails,
      hasCoveredParking: this.hasCoveredParking,
      hasCCTV: this.hasCCTV,
      imageUrl: this.imageUrl,
      description: this.description,
      levels: this.levels,
      configuration: this.configuration,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      latitude: this.latitude,
      longitude: this.longitude,
    };
  }
}
