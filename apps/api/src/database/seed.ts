import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../users/entities/user.entity';
import { AppDataSource } from './data-source';

async function seed() {
  try {
    await AppDataSource.initialize();
    console.log('Data Source has been initialized!');

    const userRepository = AppDataSource.getRepository(User);

    const superAdminEmail = 'admin@parklocator.com';
    const existingAdmin = await userRepository.findOne({
      where: { email: superAdminEmail },
    });

    if (existingAdmin) {
      console.log('Super Admin already exists.');
      // Update role if it's not SUPER_ADMIN (e.g. if it was previously a MANAGER)
      if (existingAdmin.role !== UserRole.SUPER_ADMIN) {
        existingAdmin.role = UserRole.SUPER_ADMIN;
        await userRepository.save(existingAdmin);
        console.log('Updated existing admin role to SUPER_ADMIN');
      }
    } else {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      const superAdmin = userRepository.create({
        email: superAdminEmail,
        password: hashedPassword,
        role: UserRole.SUPER_ADMIN,
      });
      await userRepository.save(superAdmin);
      console.log('Super Admin created successfully.');
      console.log('Email: admin@parklocator.com');
      console.log('Password: admin123');
    }

    await AppDataSource.destroy();
  } catch (err) {
    console.error('Error during seeding:', err);
    process.exit(1);
  }
}

void seed();
