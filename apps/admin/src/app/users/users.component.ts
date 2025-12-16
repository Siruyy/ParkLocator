import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UsersService, User, QueryUsersDto } from '../core/services/users.service';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';

interface UserViewModel extends Omit<User, 'role'> {
  role: 'driver' | 'manager' | 'attendant' | 'finance';
  name: string;
  status: 'active' | 'inactive' | 'locked';
  avatarColor: string;
  initials: string;
}

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    SidebarComponent,
    HeaderComponent
  ],
  templateUrl: './users.component.html',
  styleUrl: './users.component.scss'
})
export class UsersComponent implements OnInit {
  private usersService = inject(UsersService);

  users = signal<UserViewModel[]>([]);
  totalRecords = signal<number>(0);
  loading = signal<boolean>(false);

  // Stats
  stats = {
    totalUsers: 24,
    activeNow: 8,
    managers: 3,
    attendants: 15
  };

  // Filters
  searchQuery = '';
  selectedRole: string = '';
  selectedStatus: string = '';

  private searchSubject = new Subject<string>();
  
  // Pagination
  currentPage = 1;
  totalPages = 1;
  limit = 10;

  ngOnInit() {
    this.loadUsers();

    this.searchSubject.pipe(
      debounceTime(500),
      distinctUntilChanged()
    ).subscribe(query => {
      this.searchQuery = query;
      this.currentPage = 1;
      this.loadUsers();
    });
  }

  onSearch(event: Event) {
    const value = (event.target as HTMLInputElement).value;
    this.searchSubject.next(value);
  }

  onRoleChange(event: Event) {
    this.selectedRole = (event.target as HTMLSelectElement).value;
    this.currentPage = 1;
    this.loadUsers();
  }

  onStatusChange(event: Event) {
    this.selectedStatus = (event.target as HTMLSelectElement).value;
    this.currentPage = 1;
    // In a real app, we'd filter by status via API
  }

  changePage(page: number) {
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page;
      this.loadUsers();
    }
  }

  loadUsers() {
    this.loading.set(true);
    
    const query: QueryUsersDto = {
      page: this.currentPage,
      limit: this.limit,
      search: this.searchQuery,
      role: this.selectedRole || undefined
    };

    this.usersService.getUsers(query).subscribe({
      next: (response) => {
        const mappedUsers: UserViewModel[] = response.data.map(user => ({
          ...user,
          name: user.email.split('@')[0].replace('.', ' '), // Mock name from email
          status: Math.random() > 0.2 ? 'active' : (Math.random() > 0.5 ? 'inactive' : 'locked'), // Mock status
          avatarColor: this.getRandomColor(),
          initials: user.email.substring(0, 2).toUpperCase()
        }));
        
        this.users.set(mappedUsers);
        this.totalRecords.set(response.meta.total);
        this.totalPages = response.meta.totalPages;
        this.loading.set(false);
      },
      error: (error) => {
        console.error('Error loading users', error);
        this.loading.set(false);
        // Fallback to mock data if API fails or is empty (for demo purposes)
        if (this.users().length === 0) {
            this.loadMockUsers();
        }
      }
    });
  }

  getRandomColor() {
    const colors = ['bg-blue-100 text-blue-700', 'bg-green-100 text-green-700', 'bg-purple-100 text-purple-700', 'bg-orange-100 text-orange-700', 'bg-pink-100 text-pink-700', 'bg-teal-100 text-teal-700'];
    return colors[Math.floor(Math.random() * colors.length)];
  }

  loadMockUsers() {
      // Mock data matching the design
      const mockUsers: UserViewModel[] = [
          { id: '1', email: 'juan.delacruz@parklocator.com', role: 'manager', createdAt: '2023-10-24', updatedAt: '', name: 'Juan Dela Cruz', status: 'active', avatarColor: 'bg-blue-100 text-blue-700', initials: 'JD' },
          { id: '2', email: 'maria.santos@parklocator.com', role: 'attendant', createdAt: '2023-11-12', updatedAt: '', name: 'Maria Santos', status: 'active', avatarColor: 'bg-orange-100 text-orange-700', initials: 'MS' },
          { id: '3', email: 'pedro.p@parklocator.com', role: 'finance', createdAt: '2023-08-05', updatedAt: '', name: 'Pedro Penduko', status: 'inactive', avatarColor: 'bg-teal-100 text-teal-700', initials: 'PP' },
          { id: '4', email: 'anna.reyes@parklocator.com', role: 'attendant', createdAt: '2023-12-01', updatedAt: '', name: 'Anna Reyes', status: 'active', avatarColor: 'bg-pink-100 text-pink-700', initials: 'AR' },
          { id: '5', email: 'miguel.tan@parklocator.com', role: 'manager', createdAt: '2024-01-15', updatedAt: '', name: 'Miguel Tan', status: 'locked', avatarColor: 'bg-indigo-100 text-indigo-700', initials: 'MT' },
      ];
      this.users.set(mockUsers);
      this.totalRecords.set(24);
      this.totalPages = 3;
  }
}
