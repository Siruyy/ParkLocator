import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent {
  menuItems = [
    { label: 'Dashboard', icon: 'dashboard', route: '/dashboard' },
    { label: 'Venue Config', icon: 'map', route: '/venues' },
    { label: 'Reservations', icon: 'calendar_month', route: '/reservations', badge: 12 },
    { label: 'QR Logs', icon: 'qr_code_scanner', route: '/qr-logs' },
    { label: 'Finance', icon: 'account_balance_wallet', route: '/finance' }
  ];
}
