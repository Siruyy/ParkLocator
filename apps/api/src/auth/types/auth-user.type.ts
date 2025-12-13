import { UserRole } from '../../users/entities/user.entity';

/**
 * Type representing an authenticated user in the request context
 * This is the user object added to the request by Passport JWT strategy
 */
export interface AuthUser {
  userId: string;
  email: string;
  role: UserRole;
}
