import { IsString, IsOptional, IsBoolean } from 'class-validator';

export class UpdateVehicleDto {
  @IsString()
  @IsOptional()
  plateNumber?: string;

  @IsString()
  @IsOptional()
  make?: string;

  @IsString()
  @IsOptional()
  model?: string;

  @IsString()
  @IsOptional()
  color?: string;

  @IsString()
  @IsOptional()
  type?: string;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;

  @IsString()
  @IsOptional()
  photoUrl?: string;
}
