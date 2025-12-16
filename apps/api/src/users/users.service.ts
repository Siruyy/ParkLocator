import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { QueryUsersDto } from './dto/query-users.dto';

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
  ) {}

  async findAll(query: QueryUsersDto, currentUser?: User): Promise<PaginatedUsers> {
    const { search, role, page = 1, limit = 20 } = query;
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
    }

    if (search) {
      queryBuilder.where('user.email ILIKE :search', {
        search: `%${search}%`,
      });
    }

    if (role) {
      queryBuilder.andWhere('user.role = :role', { role });
    }

    queryBuilder
      .select([
        'user.id',
        'user.email',
        'user.role',
        'user.createdAt',
        'user.updatedAt',
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

  async findOne(id: string): Promise<Omit<User, 'password'>> {
    const user = await this.usersRepository.findOne({
      where: { id },
      select: ['id', 'email', 'role', 'createdAt', 'updatedAt'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
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
}
