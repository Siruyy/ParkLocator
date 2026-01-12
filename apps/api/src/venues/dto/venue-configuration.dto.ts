import {
  IsArray,
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
  IsEnum,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum FeeTrigger {
  ENTRY = 'ENTRY',
  EXIT = 'EXIT',
}

export class PenaltyDto {
  @IsString()
  name: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  price: number;
}

export class CustomFeeDto extends PenaltyDto {
  @IsEnum(FeeTrigger)
  @IsOptional()
  trigger: FeeTrigger = FeeTrigger.EXIT;
}

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

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CustomFeeDto)
  customFees?: CustomFeeDto[];
}
