import {
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
  IsArray,
} from 'class-validator';
import { Type } from 'class-transformer';

export class SectionDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsInt()
  @Min(1)
  totalCapacity: number;

  @IsString()
  @IsOptional()
  vehicleType?: string;
}

export class CreateLevelDto {
  @IsInt()
  @IsNotEmpty()
  levelNumber: number;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsInt()
  @Min(1)
  @IsNotEmpty()
  totalCapacity: number;

  @IsBoolean()
  @IsOptional()
  isCovered?: boolean;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  vehicleTypes?: string[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionDto)
  @IsOptional()
  sections?: SectionDto[];
}

export class UpdateLevelDto {
  @IsInt()
  @IsOptional()
  levelNumber?: number;

  @IsString()
  @IsOptional()
  name?: string;

  @IsInt()
  @Min(1)
  @IsOptional()
  totalCapacity?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsBoolean()
  @IsOptional()
  isCovered?: boolean;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  vehicleTypes?: string[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SectionDto)
  @IsOptional()
  sections?: SectionDto[];
}

export class LevelResponseDto {
  id: string;
  levelNumber: number;
  name: string;
  totalCapacity: number;
  availableSpots: number;
  isActive: boolean;
  isCovered: boolean;
  venueId: string;
  createdAt: string;
  updatedAt: string;
}

export class LevelAvailabilityDto {
  id: string;
  levelNumber: number;
  name: string;
  totalCapacity: number;
  availableSpots: number;
  isCovered: boolean;
  occupancyPercent: number;
}
