import { Component, inject } from '@angular/core';
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

  menuItems = [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard' },
    { label: 'User Management', icon: 'group', route: '/users' },
    { label: 'Venue Config', icon: 'map', route: '/venues' },
    { label: 'Reservations', icon: 'calendar_month', route: '/reservations', badge: 12 },
    { label: 'Finance', icon: 'account_balance_wallet', route: '/finance' },
    { label: 'Logs', icon: 'qr_code_scanner', route: '/logs' }
  ];

  logout() {
    this.authService.logout();
  }
}
