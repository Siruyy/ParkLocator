import { IsString, IsNotEmpty, IsOptional, IsBoolean } from 'class-validator';

export class CreateVehicleDto {
  @IsString()
  @IsNotEmpty()
  plateNumber: string;

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
  type?: string = 'car';

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}
