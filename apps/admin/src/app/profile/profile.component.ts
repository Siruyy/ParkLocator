import { Component, inject, computed, signal, OnInit, Signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { AuthService, User } from '../core/services/auth.service';
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
  
  user: Signal<User | null> = this.authService.currentUser;
  profileForm: FormGroup;
  passwordForm: FormGroup;
  isSubmitting = signal(false);
  isChangingPassword = signal(false);
  isUploadingAvatar = signal(false);
  
  constructor() {
    this.profileForm = this.fb.group({
      employeeId: [''],
      department: [''],
      location: ['']
    });

    this.passwordForm = this.fb.group({
      currentPassword: ['', Validators.required],
      newPassword: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });
  }

  passwordMatchValidator(g: FormGroup) {
    return g.get('newPassword')?.value === g.get('confirmPassword')?.value
      ? null : { mismatch: true };
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
        this.isSubmitting.set(false);
        this.authService.updateCurrentUser(updatedUser as any);
        alert('Profile updated successfully');
      },
      error: (err) => {
        console.error('Failed to update profile', err);
        this.isSubmitting.set(false);
        alert('Failed to update profile');
      }
    });
  }

  onChangePassword() {
    if (this.passwordForm.invalid) return;

    this.isChangingPassword.set(true);
    const { newPassword } = this.passwordForm.value;

    this.usersService.changePassword(newPassword).subscribe({
      next: () => {
        this.isChangingPassword.set(false);
        this.passwordForm.reset();
        alert('Password updated successfully');
      },
      error: (err) => {
        console.error('Failed to update password', err);
        this.isChangingPassword.set(false);
        alert('Failed to update password');
      }
    });
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (!file) return;

    this.isUploadingAvatar.set(true);
    this.usersService.uploadAvatar(file).subscribe({
      next: (updatedUser) => {
        this.isUploadingAvatar.set(false);
        this.authService.updateCurrentUser(updatedUser as any);
        alert('Avatar updated successfully');
      },
      error: (err) => {
        console.error('Failed to upload avatar', err);
        this.isUploadingAvatar.set(false);
        alert('Failed to upload avatar');
      }
    });
  }
}

