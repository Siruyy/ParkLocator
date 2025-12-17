import { IsBoolean, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateVenueConfigurationDto {
  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  reservationFee?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  baseRate?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  baseDuration?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  succeedingHourRate?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  weekendSurcharge?: number;

  @IsBoolean()
  @IsOptional()
  isWeekendSurchargeActive?: boolean;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  motorcycleFlatRate?: number;

  @IsBoolean()
  @IsOptional()
  isMotorcycleFlatRateActive?: boolean;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  overnightFlatRate?: number;

  @IsString()
  @IsOptional()
  overnightStartHour?: string;

  @IsString()
  @IsOptional()
  overnightEndHour?: string;

  @IsBoolean()
  @IsOptional()
  isOvernightParkingActive?: boolean;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  entryGracePeriod?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  exitGracePeriod?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  maxReservationHold?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  lostTicketPenalty?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  illegalParkingPenalty?: number;
}
