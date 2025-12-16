import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { UsersService, PaginatedUsers } from './users.service';
import { UpdateRoleDto } from './dto/update-role.dto';
import { QueryUsersDto } from './dto/query-users.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole, User } from './entities/user.entity';
import type { AuthUser } from '../auth/types/auth-user.type';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Get all users with optional filtering and pagination
   * Only accessible by Managers and Super Admins
   */
  @Get()
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async findAll(
    @Query() query: QueryUsersDto,
    @CurrentUser() currentUser: User,
  ): Promise<PaginatedUsers> {
    return this.usersService.findAll(query, currentUser);
  }

  /**
   * Get a single user by ID
   * Only accessible by Managers and Super Admins
   */
  @Get(':id')
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<Omit<User, 'password'>> {
    return this.usersService.findOne(id);
  }

  /**
   * Update a user's role
   * Only accessible by Managers
   */
  @Patch(':id/role')
  @Roles(UserRole.MANAGER)
  async updateRole(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateRoleDto: UpdateRoleDto,
    @CurrentUser() currentUser: AuthUser,
  ): Promise<Omit<User, 'password'>> {
    return this.usersService.updateRole(id, updateRoleDto.role, currentUser.userId);
  }

  /**
   * Delete a user
   * Only accessible by Managers
   */
  @Delete(':id')
  @Roles(UserRole.MANAGER)
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() currentUser: AuthUser,
  ): Promise<{ message: string }> {
    await this.usersService.delete(id, currentUser.userId);
    return { message: 'User deleted successfully' };
  }
}
