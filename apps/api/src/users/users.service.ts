import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole, UserStatus } from './entities/user.entity';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUsersDto } from './dto/query-users.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { AuditService } from '../audit/audit.service';

export interface PaginatedUsers {
  data: Omit<User, 'password'>[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    private readonly auditService: AuditService,
  ) {}

  async findAll(query: QueryUsersDto, currentUser?: User): Promise<PaginatedUsers> {
    const { search, role, venueId, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.usersRepository.createQueryBuilder('user');

    // Filter by venue if Manager
    if (currentUser && currentUser.role === UserRole.MANAGER) {
      if (currentUser.venueId) {
        queryBuilder.andWhere('user.venueId = :venueId', { venueId: currentUser.venueId });
      } else {
        // Manager with no venue sees nothing (or maybe just themselves?)
        queryBuilder.andWhere('1 = 0'); 
      }
    } else if (venueId) {
      // Super Admin filtering by venue
      queryBuilder.andWhere('user.venueId = :venueId', { venueId });
    }

    if (search) {
      queryBuilder.where('user.email ILIKE :search', {
        search: `%${search}%`,
      });
    }

    if (role) {
      queryBuilder.andWhere('user.role = :role', { role });
    }

    if (query.status) {
      queryBuilder.andWhere('user.status = :status', { status: query.status });
    }

    queryBuilder
      .leftJoin('user.venue', 'venue')
      .select([
        'user.id',
        'user.email',
        'user.role',
        'user.status',
        'user.createdAt',
        'user.updatedAt',
        'venue.name',
        'venue.id'
      ])
      .orderBy('user.createdAt', 'DESC')
      .skip(skip)
      .take(limit);

    const [users, total] = await queryBuilder.getManyAndCount();

    return {
      data: users,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async create(createUserDto: CreateUserDto): Promise<Omit<User, 'password'>> {
    const { email, password, role, venueId } = createUserDto;
    
    const existingUser = await this.usersRepository.findOne({ where: { email } });
    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = this.usersRepository.create({
      email,
      password: hashedPassword,
      role,
      venueId
    });

    await this.usersRepository.save(user);
    
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password: _, ...result } = user;
    return result;
  }

  async findOne(id: string): Promise<Omit<User, 'password'>> {
    const user = await this.usersRepository.findOne({
      where: { id },
      relations: ['venue'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = user;
    return result;
  }

  async updateProfile(id: string, updateUserDto: UpdateUserDto): Promise<Omit<User, 'password'>> {
    await this.usersRepository.update(id, updateUserDto);
    return this.findOne(id);
  }

  async updateRole(
    id: string,
    newRole: UserRole,
    currentUserId: string,
  ): Promise<Omit<User, 'password'>> {
    // Prevent users from changing their own role
    if (id === currentUserId) {
      throw new ForbiddenException('You cannot change your own role');
    }

    const user = await this.usersRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    user.role = newRole;
    await this.usersRepository.save(user);

    // Return user without password
    const { password, ...result } = user;
    return result;
  }

  async updateStatus(
    id: string,
    newStatus: UserStatus,
    currentUserId: string,
  ): Promise<Omit<User, 'password'>> {
    // Prevent users from changing their own status
    if (id === currentUserId) {
      throw new ForbiddenException('You cannot change your own status');
    }

    const user = await this.usersRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    user.status = newStatus;
    await this.usersRepository.save(user);

    // Return user without password
    const { password, ...result } = user;
    return result;
  }

  async delete(id: string, currentUserId: string): Promise<void> {
    // Prevent users from deleting themselves
    if (id === currentUserId) {
      throw new ForbiddenException('You cannot delete your own account');
    }

    const user = await this.usersRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    await this.usersRepository.remove(user);
  }

  async changePassword(id: string, newPassword: string): Promise<void> {
    const user = await this.usersRepository.findOne({ where: { id } });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const salt = await bcrypt.genSalt();
    user.password = await bcrypt.hash(newPassword, salt);
    
    await this.usersRepository.save(user);

    await this.auditService.log(
      'CHANGE_PASSWORD',
      'User changed their password',
      id,
      id,
      'User'
    );
  }
}
