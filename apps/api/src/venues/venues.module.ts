import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  VenuesController,
  LevelsController,
  SpotsController,
} from './venues.controller';
import { VenuesService } from './venues.service';
import { Venue, Level, Spot, VenueConfiguration } from './entities';

@Module({
  imports: [TypeOrmModule.forFeature([Venue, Level, Spot, VenueConfiguration])],
  controllers: [VenuesController, LevelsController, SpotsController],
  providers: [VenuesService],
  exports: [VenuesService],
})
export class VenuesModule {}
