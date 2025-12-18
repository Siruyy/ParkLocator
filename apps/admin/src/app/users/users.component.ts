import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { UsersService, User, QueryUsersDto } from '../core/services/users.service';
import { DashboardService } from '../core/services/dashboard.service';
import { VenuesService, Venue } from '../core/services/venues.service';
import { AuthService } from '../core/services/auth.service';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { SelectModule } from 'primeng/select';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { CardModule } from 'primeng/card';
import { TooltipModule } from 'primeng/tooltip';

interface UserViewModel extends Omit<User, 'role'> {
  role: 'super_admin' | 'driver' | 'manager' | 'attendant' | 'finance';
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
    ReactiveFormsModule,
    SidebarComponent,
    HeaderComponent,
    TableModule,
    ButtonModule,
    InputTextModule,
    IconFieldModule,
    InputIconModule,
    SelectModule,
    TagModule,
    DialogModule,
    CardModule,
    TooltipModule
  ],
  templateUrl: './users.component.html',
  styleUrl: './users.component.scss'
})
export class UsersComponent implements OnInit {
  private usersService = inject(UsersService);
  private dashboardService = inject(DashboardService);
  private venuesService = inject(VenuesService);
  private authService = inject(AuthService);
  private fb = inject(FormBuilder);

  users = signal<UserViewModel[]>([]);
  totalRecords = signal<number>(0);
  loading = signal<boolean>(false);

  // Auth & Roles
  isSuperAdmin = computed(() => this.authService.currentUser()?.role === 'super_admin');
  isManager = computed(() => this.authService.currentUser()?.role === 'manager');

  // Venues (for Super Admin)
  venues: Venue[] = [];
  selectedVenueId = '';

  // Form & Modal
  userForm: FormGroup;
  showUserModal = false;
  isEditing = false;
  selectedUserId: string | null = null;
  isSubmitting = false;

  // Stats
  stats = {
    totalUsers: 0,
    activeNow: 0,
    managers: 0,
    attendants: 0
  };

  // Filters
  searchQuery = '';
  selectedRole: string = '';
  selectedStatus: string = '';

  roleOptions = [
    { label: 'All Roles', value: '' },
    { label: 'Mall Manager', value: 'manager' },
    { label: 'Attendant', value: 'attendant' },
    { label: 'Finance', value: 'finance' },
    { label: 'Driver', value: 'driver' }
  ];

  statusOptions = [
    { label: 'Status: All', value: '' },
    { label: 'Active', value: 'active' },
    { label: 'Inactive', value: 'inactive' },
    { label: 'Locked', value: 'locked' }
  ];

  private searchSubject = new Subject<string>();
  
  // Pagination
  currentPage = 1;
  totalPages = 1;
  limit = 10;

  constructor() {
    this.userForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      role: ['manager', Validators.required],
      venueId: ['']
    });
  }

  ngOnInit() {
    if (this.isSuperAdmin()) {
      this.loadVenues();
    }
    this.loadUsers();
    this.loadStats();

    this.searchSubject.pipe(
      debounceTime(500),
      distinctUntilChanged()
    ).subscribe(query => {
      this.searchQuery = query;
      this.currentPage = 1;
      this.loadUsers();
    });
  }

  loadVenues() {
    this.venuesService.getVenues().subscribe(venues => {
      this.venues = venues;
    });
  }

  onVenueFilterChange(event: Event) {
    this.selectedVenueId = (event.target as HTMLSelectElement).value;
    this.currentPage = 1;
    this.loadUsers();
  }

  loadStats() {
    this.dashboardService.getStats().subscribe(data => {
      this.stats = data.userStats;
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
    this.loadUsers();
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
      role: this.selectedRole || undefined,
      status: this.selectedStatus || undefined,
      venueId: this.selectedVenueId || undefined
    };

    this.usersService.getUsers(query).subscribe({
      next: (response) => {
        const mappedUsers: UserViewModel[] = response.data.map(user => ({
          ...user,
          name: user.email.split('@')[0].replace('.', ' '), // Mock name from email
          status: user.status || 'active',
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

  openAddUserModal() {
    this.isEditing = false;
    this.selectedUserId = null;
    
    // Default role based on user type
    const defaultRole = this.isManager() ? 'attendant' : 'manager';
    
    this.userForm.reset({
      role: defaultRole,
      venueId: this.selectedVenueId || '' // Pre-select venue if filtered
    });
    this.userForm.get('password')?.setValidators([Validators.required, Validators.minLength(6)]);
    this.userForm.get('password')?.updateValueAndValidity();
    this.showUserModal = true;
  }

  openEditUserModal(user: UserViewModel) {
    this.isEditing = true;
    this.selectedUserId = user.id;
    this.userForm.patchValue({
      email: user.email,
      role: user.role
    });
    // Password not required for edit
    this.userForm.get('password')?.clearValidators();
    this.userForm.get('password')?.updateValueAndValidity();
    this.showUserModal = true;
  }

  closeUserModal() {
    this.showUserModal = false;
  }

  onSubmitUser() {
    if (this.userForm.invalid) return;

    this.isSubmitting = true;
    const formData = this.userForm.value;

    if (this.isEditing && this.selectedUserId) {
      // Update (Role only for now)
      this.usersService.updateRole(this.selectedUserId, formData.role).subscribe({
        next: () => {
          this.isSubmitting = false;
          this.closeUserModal();
          this.loadUsers();
        },
        error: (err) => {
          console.error('Failed to update user', err);
          this.isSubmitting = false;
        }
      });
    } else {
      // Create
      this.usersService.createUser(formData).subscribe({
        next: () => {
          this.isSubmitting = false;
          this.closeUserModal();
          this.loadUsers();
        },
        error: (err) => {
          console.error('Failed to create user', err);
          this.isSubmitting = false;
        }
      });
    }
  }

  deleteUser(user: UserViewModel) {
    if (confirm(`Are you sure you want to delete ${user.email}?`)) {
      this.usersService.deleteUser(user.id).subscribe({
        next: () => {
          this.loadUsers();
        },
        error: (err) => {
          console.error('Failed to delete user', err);
        }
      });
    }
  }

  toggleUserStatus(user: UserViewModel) {
    const newStatus = user.status === 'active' ? 'inactive' : 'active';
    const action = newStatus === 'active' ? 'activate' : 'deactivate';
    
    if (confirm(`Are you sure you want to ${action} ${user.email}?`)) {
      this.usersService.updateStatus(user.id, newStatus).subscribe({
        next: () => {
          this.loadUsers();
        },
        error: (err) => {
          console.error(`Failed to ${action} user`, err);
        }
      });
    }
  }

  resetPassword(user: UserViewModel) {
    alert(`Reset password link sent to ${user.email}`);
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
