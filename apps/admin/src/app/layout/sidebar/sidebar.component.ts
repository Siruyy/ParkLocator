import { Component, inject, computed, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';
import { ReservationsService } from '../../core/services/reservations.service';

interface MenuItem {
  label: string;
  icon: string;
  route: string;
  roles: string[];
  badge?: number;
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent implements OnInit {
  private authService = inject(AuthService);
  private reservationsService = inject(ReservationsService);
  
  user = this.authService.currentUser;

  menuItems = signal<MenuItem[]>([
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard', roles: ['super_admin', 'manager'] },
    { label: 'User Management', icon: 'group', route: '/users', roles: ['super_admin', 'manager'] },
    { label: 'Venue Management', icon: 'map', route: '/venues', roles: ['super_admin', 'manager'] },
    { label: 'Reservations', icon: 'calendar_month', route: '/reservations', roles: ['super_admin', 'manager'], badge: 0 },
    { label: 'Finance', icon: 'account_balance_wallet', route: '/finance', roles: ['super_admin', 'manager'] },
    { label: 'Logs', icon: 'qr_code_scanner', route: '/logs', roles: ['super_admin', 'manager'] }
  ]);

  filteredMenuItems = computed(() => {
    const userRole = this.user()?.role;
    const items = this.menuItems();
    if (!userRole) return [];
    return items.filter(item => item.roles.includes(userRole));
  });

  portalTitle = computed(() => {
    return this.user()?.role === 'super_admin' ? 'Super Admin Portal' : 'Admin Portal';
  });

  ngOnInit() {
    this.loadReservationStats();
  }

  loadReservationStats() {
    this.reservationsService.getReservations().subscribe({
      next: (reservations) => {
        // Count pending reservations
        const pendingCount = reservations.filter(r => r.status === 'pending').length;
        
        this.menuItems.update(items => items.map(item => {
          if (item.label === 'Reservations') {
            return { ...item, badge: pendingCount };
          }
          return item;
        }));
      },
      error: (err) => console.error('Failed to load reservation stats', err)
    });
  }

  logout() {
    this.authService.logout();
  }
}
