import {
  IsEmail,
  IsEnum,
  IsString,
  MinLength,
  IsOptional,
  IsUUID,
} from 'class-validator';
import { UserRole } from '../entities/user.entity';

export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsEnum(UserRole)
  role: UserRole;

  @IsOptional()
  @IsUUID()
  venueId?: string;
}
