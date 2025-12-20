import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  ParseUUIDPipe,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { UsersService, PaginatedUsers } from './users.service';
import { UpdateRoleDto } from './dto/update-role.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUsersDto } from './dto/query-users.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole, User } from './entities/user.entity';
import type { AuthUser } from '../auth/types/auth-user.type';

import { ChangePasswordDto } from './dto/change-password.dto';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Change password for the current user
   */
  @Patch('profile/password')
  async changePassword(
    @CurrentUser() currentUser: AuthUser,
    @Body() changePasswordDto: ChangePasswordDto,
  ): Promise<{ message: string }> {
    await this.usersService.changePassword(currentUser.userId, changePasswordDto.newPassword);
    return { message: 'Password updated successfully' };
  }

  @Post('profile/avatar')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads/avatars',
      filename: (req, file, cb) => {
        const randomName = Array(32).fill(null).map(() => (Math.round(Math.random() * 16)).toString(16)).join('');
        return cb(null, `${randomName}${extname(file.originalname)}`);
      }
    })
  }))
  async uploadAvatar(
    @CurrentUser() currentUser: AuthUser,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const avatarUrl = `/uploads/avatars/${file.filename}`;
    return this.usersService.updateProfile(currentUser.userId, { avatarUrl });
  }

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
   * Create a new user
   * Only accessible by Managers and Super Admins
   */
  @Post()
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async create(
    @Body() createUserDto: CreateUserDto,
    @CurrentUser() currentUser: User,
  ): Promise<Omit<User, 'password'>> {
    // If Manager, force venueId to be their venue
    if (currentUser.role === UserRole.MANAGER) {
       createUserDto.venueId = currentUser.venueId || undefined;
    }
    return this.usersService.create(createUserDto);
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
   * Update own profile
   */
  @Patch('profile')
  async updateProfile(
    @Body() updateUserDto: UpdateUserDto,
    @CurrentUser() currentUser: User,
  ): Promise<Omit<User, 'password'>> {
    return this.usersService.updateProfile(currentUser.id, updateUserDto);
  }

  /**
   * Update a user's role
   * Only accessible by Managers and Super Admins
   */
  @Patch(':id/role')
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async updateRole(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateRoleDto: UpdateRoleDto,
    @CurrentUser() currentUser: AuthUser,
  ): Promise<Omit<User, 'password'>> {
    return this.usersService.updateRole(id, updateRoleDto.role, currentUser.userId);
  }

  /**
   * Update a user's status
   * Only accessible by Managers and Super Admins
   */
  @Patch(':id/status')
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateStatusDto: UpdateStatusDto,
    @CurrentUser() currentUser: AuthUser,
  ): Promise<Omit<User, 'password'>> {
    return this.usersService.updateStatus(id, updateStatusDto.status, currentUser.userId);
  }

  /**
   * Delete a user
   * Only accessible by Managers and Super Admins
   */
  @Delete(':id')
  @Roles(UserRole.SUPER_ADMIN, UserRole.MANAGER)
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() currentUser: AuthUser,
  ): Promise<{ message: string }> {
    await this.usersService.delete(id, currentUser.userId);
    return { message: 'User deleted successfully' };
  }
}
