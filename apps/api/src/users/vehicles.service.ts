import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vehicle } from './entities/vehicle.entity';
import { CreateVehicleDto } from './dto/create-vehicle.dto';

@Injectable()
export class VehiclesService {
  constructor(
    @InjectRepository(Vehicle)
    private vehiclesRepository: Repository<Vehicle>,
  ) {}

  async create(
    userId: string,
    createVehicleDto: CreateVehicleDto,
  ): Promise<Vehicle> {
    console.log('Creating vehicle for user:', userId);
    // Check fleet limit (max 5 vehicles)
    const count = await this.vehiclesRepository.count({ where: { userId } });
    if (count >= 5) {
      throw new ConflictException(
        'You have reached the maximum limit of 5 vehicles.',
      );
    }

    // Check if plate number already exists
    const existing = await this.vehiclesRepository.findOne({
      where: { plateNumber: createVehicleDto.plateNumber },
    });

    if (existing) {
      throw new ConflictException(
        'Vehicle with this plate number already exists',
      );
    }

    const vehicle = this.vehiclesRepository.create(createVehicleDto);
    vehicle.userId = userId;

    return this.vehiclesRepository.save(vehicle);
  }

  async update(
    userId: string,
    id: string,
    updateData: Partial<Vehicle>,
  ): Promise<Vehicle> {
    const vehicle = await this.findOne(id);
    if (vehicle.userId !== userId) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }

    // If setting this vehicle as default, unset all other defaults for this user
    if (updateData.isDefault === true) {
      await this.vehiclesRepository.update(
        { userId, isDefault: true },
        { isDefault: false },
      );
    }

    Object.assign(vehicle, updateData);
    return this.vehiclesRepository.save(vehicle);
  }

  async findAll(userId: string): Promise<Vehicle[]> {
    return this.vehiclesRepository.find({
      where: { userId },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Vehicle> {
    const vehicle = await this.vehiclesRepository.findOne({ where: { id } });
    if (!vehicle) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    return vehicle;
  }

  async remove(userId: string, id: string): Promise<void> {
    const vehicle = await this.findOne(id);
    if (vehicle.userId !== userId) {
      throw new NotFoundException(`Vehicle with ID ${id} not found`);
    }
    await this.vehiclesRepository.remove(vehicle);
  }
}
