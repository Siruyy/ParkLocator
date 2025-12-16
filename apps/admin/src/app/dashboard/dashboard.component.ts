import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { CardModule } from 'primeng/card';
import { MeterGroupModule } from 'primeng/metergroup';
import { TimelineModule } from 'primeng/timeline';
import { ButtonModule } from 'primeng/button';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule, 
    RouterModule, 
    SidebarComponent, 
    HeaderComponent,
    CardModule,
    MeterGroupModule,
    TimelineModule,
    ButtonModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent {
  // Placeholder data for the dashboard
  occupancyRate = 85;
  activeReservations = 42;
  todaysRevenue = 15400;

  occupancyData = [
    { label: 'Occupied', value: 85, color: '#34d399', icon: 'pi pi-car' },
    { label: 'Available', value: 15, color: '#e5e7eb', icon: 'pi pi-check-circle' }
  ];
  
  recentActivities = [
    {
      title: 'Check-in: Toyota Fortuner',
      time: '2m ago',
      icon: 'login',
      iconBg: 'bg-blue-50 dark:bg-blue-900/20',
      iconColor: 'text-blue-600 dark:text-blue-400',
      details: 'Plate: ABC-1234 • Gate 1'
    },
    {
      title: 'Reservation Confirmed',
      time: '15m ago',
      icon: 'confirmation_number',
      iconBg: 'bg-primary/20',
      iconColor: 'text-black dark:text-primary',
      details: 'ID: #RES-9921 • Premium Slot'
    },
    {
      title: 'Check-out: Honda Civic',
      time: '42m ago',
      icon: 'logout',
      iconBg: 'bg-gray-100 dark:bg-white/10',
      iconColor: 'text-gray-600 dark:text-gray-400',
      details: 'Plate: XYZ-8888 • Duration: 2h 15m'
    }
  ];
}
