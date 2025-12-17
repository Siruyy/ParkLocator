import { Component, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent {
  private authService = inject(AuthService);
  
  user = this.authService.currentUser;

  menuItems = [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard', roles: ['super_admin', 'manager'] },
    { label: 'User Management', icon: 'group', route: '/users', roles: ['super_admin', 'manager'] },
    { label: 'Venue Config', icon: 'map', route: '/venues', roles: ['super_admin', 'manager'] },
    { label: 'Reservations', icon: 'calendar_month', route: '/reservations', badge: 12, roles: ['super_admin', 'manager'] },
    { label: 'Finance', icon: 'account_balance_wallet', route: '/finance', roles: ['super_admin', 'manager'] },
    { label: 'Logs', icon: 'qr_code_scanner', route: '/logs', roles: ['super_admin', 'manager'] }
  ];

  filteredMenuItems = computed(() => {
    const userRole = this.user()?.role;
    if (!userRole) return [];
    return this.menuItems.filter(item => item.roles.includes(userRole));
  });

  portalTitle = computed(() => {
    return this.user()?.role === 'super_admin' ? 'Super Admin Portal' : 'Admin Portal';
  });

  logout() {
    this.authService.logout();
  }
}
