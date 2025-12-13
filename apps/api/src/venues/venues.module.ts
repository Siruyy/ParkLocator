import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VenuesController, LevelsController } from './venues.controller';
import { VenuesService } from './venues.service';
import { Venue, Level, Spot } from './entities';

@Module({
  imports: [TypeOrmModule.forFeature([Venue, Level, Spot])],
  controllers: [VenuesController, LevelsController],
  providers: [VenuesService],
  exports: [VenuesService],
})
export class VenuesModule {}
