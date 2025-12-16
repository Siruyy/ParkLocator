import { IsEnum } from 'class-validator';
import { UserStatus } from '../entities/user.entity';

export class UpdateStatusDto {
  @IsEnum(UserStatus)
  status: UserStatus;
}
