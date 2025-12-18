import { Component, inject, computed, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup } from '@angular/forms';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { AuthService } from '../core/services/auth.service';
import { UsersService } from '../core/services/users.service';
import { ToggleSwitch } from 'primeng/toggleswitch';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, SidebarComponent, HeaderComponent, ToggleSwitch],
  templateUrl: './profile.component.html',
  styleUrl: './profile.component.scss'
})
export class ProfileComponent implements OnInit {
  private authService = inject(AuthService);
  private usersService = inject(UsersService);
  private fb = inject(FormBuilder);
  
  user = this.authService.currentUser;
  profileForm: FormGroup;
  isSubmitting = signal(false);
  
  constructor() {
    this.profileForm = this.fb.group({
      employeeId: [''],
      department: [''],
      location: ['']
    });
  }

  ngOnInit() {
    // Initialize form with user data
    const currentUser = this.user();
    if (currentUser) {
      this.profileForm.patchValue({
        employeeId: currentUser.employeeId || '',
        department: currentUser.department || '',
        location: currentUser.location || ''
      });
    }
  }
  
  // Derived properties for display
  displayName = computed(() => {
    const email = this.user()?.email || '';
    return email.split('@')[0].replace(/[._]/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
  });
  
  initials = computed(() => {
    const email = this.user()?.email || '';
    return email.substring(0, 2).toUpperCase();
  });

  onSubmit() {
    if (this.profileForm.invalid) return;

    this.isSubmitting.set(true);
    this.usersService.updateProfile(this.profileForm.value).subscribe({
      next: (updatedUser) => {
        // Update the auth service with new user data
        // This assumes authService has a way to update the current user signal
        // For now, we might need to reload or manually update if authService exposes a setter
        // But typically authService.currentUser is a signal derived from a BehaviorSubject or similar
        
        // Ideally: this.authService.updateCurrentUser(updatedUser);
        // Since we don't have that, we'll just stop loading
        this.isSubmitting.set(false);
        alert('Profile updated successfully');
      },
      error: (err) => {
        console.error('Failed to update profile', err);
        this.isSubmitting.set(false);
        alert('Failed to update profile');
      }
    });
  }
}
