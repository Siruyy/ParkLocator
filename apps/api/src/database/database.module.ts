import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User } from '../users/entities/user.entity';
import { Vehicle } from '../users/entities/vehicle.entity';
import { Venue, Level, Spot, VenueConfiguration } from '../venues/entities';
import { Reservation } from '../reservations/entities/reservation.entity';
import { AuditLog } from '../audit/entities/audit-log.entity';
import { Notification } from '../notifications/entities/notification.entity';

@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get('DB_HOST'),
        port: configService.get('DB_PORT'),
        username: configService.get('DB_USER'),
        password: configService.get('DB_PASSWORD'),
        database: configService.get('DB_NAME'),
        entities: [User, Vehicle, Venue, Level, Spot, VenueConfiguration, Reservation, AuditLog, Notification],
        synchronize: true, // Enabled for dev to update schema
      }),
    }),
  ],
})
export class DatabaseModule {}
