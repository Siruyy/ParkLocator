import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { VehiclesController } from './vehicles.controller';
import { VehiclesService } from './vehicles.service';
import { User } from './entities/user.entity';
import { Vehicle } from './entities/vehicle.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Vehicle])],
  controllers: [UsersController, VehiclesController],
  providers: [UsersService, VehiclesService],
  exports: [UsersService, VehiclesService],
})
export class UsersModule {}
