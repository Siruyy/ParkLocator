import { IsEnum, IsNotEmpty } from 'class-validator';
import { UserRole } from '../entities/user.entity';

export class UpdateRoleDto {
  @IsNotEmpty()
  @IsEnum(UserRole, { message: 'Role must be one of: driver, manager, attendant' })
  role: UserRole;
}
