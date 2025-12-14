import {
  IsUUID,
  IsOptional,
  IsInt,
  Min,
  Max,
} from 'class-validator';

export class CreateReservationDto {
  @IsUUID()
  venueId: string;

  @IsUUID()
  levelId: string;

  @IsUUID()
  spotId: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(24)
  durationHours?: number = 1;
}
