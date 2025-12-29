import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReservationsService } from './reservations.service';
import { ReservationsController } from './reservations.controller';
import { Reservation } from './entities/reservation.entity';
import { Spot } from '../venues/entities/spot.entity';
import { Level } from '../venues/entities/level.entity';
import { Venue } from '../venues/entities/venue.entity';
import { VenueConfiguration } from '../venues/entities/venue-configuration.entity';
import { UsersModule } from '../users/users.module';
import { AuditModule } from '../audit/audit.module';
import { EventsModule } from '../events/events.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Reservation,
      Spot,
      Level,
      Venue,
      VenueConfiguration,
    ]),
    UsersModule,
    AuditModule,
    EventsModule,
    NotificationsModule,
  ],
  controllers: [ReservationsController],
  providers: [ReservationsService],
  exports: [ReservationsService],
})
export class ReservationsModule {}
