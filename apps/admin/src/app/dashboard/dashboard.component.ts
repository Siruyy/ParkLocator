import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule, SidebarComponent, HeaderComponent],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent {
  // Placeholder data for the dashboard
  occupancyRate = 85;
  activeReservations = 42;
  todaysRevenue = 15400;
  
  recentActivities = [
    {
      type: 'check-in',
      title: 'Check-in: Toyota Fortuner',
      details: 'Plate: ABC-1234 • Gate 1',
      time: '2m ago',
      icon: 'login',
      iconClass: 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
    },
    {
      type: 'reservation',
      title: 'Reservation Confirmed',
      details: 'ID: #RES-9921 • Premium Slot',
      time: '15m ago',
      icon: 'confirmation_number',
      iconClass: 'bg-primary/20 text-black dark:text-primary'
    },
    {
      type: 'check-out',
      title: 'Check-out: Honda Civic',
      details: 'Plate: XYZ-8888 • Duration: 2h 15m',
      time: '42m ago',
      icon: 'logout',
      iconClass: 'bg-gray-100 dark:bg-white/10 text-gray-600 dark:text-gray-400'
    }
  ];
}
