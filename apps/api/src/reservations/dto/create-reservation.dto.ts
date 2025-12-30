import {
  IsUUID,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsDateString,
} from 'class-validator';

export class CreateReservationDto {
  @IsUUID()
  venueId: string;

  @IsUUID()
  levelId: string;

  @IsUUID()
  spotId: string;

  @IsOptional()
  @IsUUID()
  vehicleId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  durationHours?: number = 1;

  @IsOptional()
  @IsDateString()
  startAt?: string; // ISO date string for "Book for Later"

  @IsOptional()
  @IsDateString()
  endAt?: string; // ISO date string for "Book for Later"
}
