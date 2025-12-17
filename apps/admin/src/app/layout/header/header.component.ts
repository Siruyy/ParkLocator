import { Component, Input, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

export interface BreadcrumbItem {
  label: string;
  url?: string;
  queryParams?: any;
}

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './header.component.html',
  styleUrl: './header.component.scss',
})
export class HeaderComponent {
  @Input() breadcrumbs: BreadcrumbItem[] = [];
  @Input() searchPlaceholder: string = 'Search...';

  private authService = inject(AuthService);
  user = this.authService.currentUser;

  displayName = computed(() => {
    const u = this.user();
    if (u?.firstName && u?.lastName) {
      return `${u.firstName} ${u.lastName}`;
    }
    return u?.email || 'User';
  });

  displayRole = computed(() => {
    const role = this.user()?.role;
    if (!role) return '';
    return role.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
  });
}
