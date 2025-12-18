import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DialogModule } from 'primeng/dialog';
import { ButtonModule } from 'primeng/button';
import { DatePickerModule } from 'primeng/datepicker';
import { SelectModule } from 'primeng/select';
import { SelectButtonModule } from 'primeng/selectbutton';
import { TableModule } from 'primeng/table';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { InputTextModule } from 'primeng/inputtext';
import { CardModule } from 'primeng/card';
import { ProgressBarModule } from 'primeng/progressbar';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';

interface Reservation {
  id: string;
  user: {
    name: string;
    email: string;
    avatar?: string;
  };
  vehicle: {
    plateNumber: string;
    model: string;
  };
  venue: string;
  spotId: string;
  startTime: Date;
  endTime: Date;
  status: 'active' | 'completed' | 'cancelled' | 'pending';
  amount: number;
}

@Component({
  selector: 'app-reservations',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule, 
    DialogModule, 
    ButtonModule, 
    DatePickerModule, 
    SelectModule,
    SelectButtonModule,
    TableModule,
    IconFieldModule,
    InputIconModule,
    InputTextModule,
    CardModule,
    ProgressBarModule,
    SidebarComponent, 
    HeaderComponent
  ],
  templateUrl: './reservations.component.html',
  styleUrl: './reservations.component.scss'
})
export class ReservationsComponent {
  selectedVenue = 'All Venues';
  selectedDate: Date = new Date();
  selectedStatus = 'All Status';
  
  displayDialog = false;
  selectedReservation: Reservation | null = null;

  venues = ['All Venues', 'Downtown Garage', 'Mall Plaza Parking', 'Central Station Lot', 'Airport Terminal 1'];
  
  statusOptions = [
    { label: 'All Status', value: 'All Status' },
    { label: 'Active', value: 'Active' },
    { label: 'Completed', value: 'Completed' },
    { label: 'Cancelled', value: 'Cancelled' }
  ];

  reservations: Reservation[] = [
    {
      id: 'RES-2024-001',
      user: { name: 'John Doe', email: 'john@example.com' },
      vehicle: { plateNumber: 'ABC 1234', model: 'Toyota Camry' },
      venue: 'Downtown Garage',
      spotId: 'A-12',
      startTime: new Date(new Date().setHours(8, 0, 0, 0)),
      endTime: new Date(new Date().setHours(17, 0, 0, 0)),
      status: 'active',
      amount: 15.00
    },
    {
      id: 'RES-2024-002',
      user: { name: 'Jane Smith', email: 'jane@example.com' },
      vehicle: { plateNumber: 'XYZ 9876', model: 'Honda Civic' },
      venue: 'Mall Plaza Parking',
      spotId: 'B-05',
      startTime: new Date(new Date().setHours(10, 30, 0, 0)),
      endTime: new Date(new Date().setHours(14, 30, 0, 0)),
      status: 'completed',
      amount: 8.50
    },
    {
      id: 'RES-2024-003',
      user: { name: 'Mike Johnson', email: 'mike@example.com' },
      vehicle: { plateNumber: 'LMN 4567', model: 'Ford F-150' },
      venue: 'Downtown Garage',
      spotId: 'C-22',
      startTime: new Date(new Date().setHours(9, 0, 0, 0)),
      endTime: new Date(new Date().setHours(11, 0, 0, 0)),
      status: 'cancelled',
      amount: 0
    },
    {
      id: 'RES-2024-004',
      user: { name: 'Sarah Wilson', email: 'sarah@example.com' },
      vehicle: { plateNumber: 'DEF 3210', model: 'Tesla Model 3' },
      venue: 'Central Station Lot',
      spotId: 'EV-01',
      startTime: new Date(new Date().setHours(13, 0, 0, 0)),
      endTime: new Date(new Date().setHours(18, 0, 0, 0)),
      status: 'pending',
      amount: 25.00
    },
    {
      id: 'RES-2024-005',
      user: { name: 'Robert Brown', email: 'robert@example.com' },
      vehicle: { plateNumber: 'GHI 7890', model: 'BMW X5' },
      venue: 'Downtown Garage',
      spotId: 'A-15',
      startTime: new Date(new Date().setHours(14, 0, 0, 0)),
      endTime: new Date(new Date().setHours(16, 0, 0, 0)),
      status: 'active',
      amount: 12.00
    }
  ];

  get filteredReservations() {
    return this.reservations.filter(res => {
      const venueMatch = this.selectedVenue === 'All Venues' || res.venue === this.selectedVenue;
      const statusMatch = this.selectedStatus === 'All Status' || res.status.toLowerCase() === this.selectedStatus.toLowerCase();
      
      let dateMatch = true;
      if (this.selectedDate) {
        const resDate = new Date(res.startTime);
        dateMatch = resDate.getDate() === this.selectedDate.getDate() &&
                    resDate.getMonth() === this.selectedDate.getMonth() &&
                    resDate.getFullYear() === this.selectedDate.getFullYear();
      }

      return venueMatch && statusMatch && dateMatch;
    });
  }

  get stats() {
    const filtered = this.filteredReservations;
    const todayCheckins = filtered.filter(r => r.status === 'active' || r.status === 'completed').length;
    const pending = filtered.filter(r => r.status === 'pending').length;
    
    // Mock occupancy calculation
    const totalSpots = 500; // This would normally come from venue data
    const occupied = filtered.filter(r => r.status === 'active').length + 400; // +400 mock base load
    const occupancyRate = Math.round((occupied / totalSpots) * 100);

    return {
      todayCheckins,
      pending,
      occupancyRate,
      occupiedSpots: occupied,
      totalSpots
    };
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border-green-200 dark:border-green-800';
      case 'completed': return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border-blue-200 dark:border-blue-800';
      case 'cancelled': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400 border-red-200 dark:border-red-800';
      case 'pending': return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border-yellow-200 dark:border-yellow-800';
      default: return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400 border-gray-200 dark:border-gray-700';
    }
  }

  showDetails(reservation: Reservation) {
    this.selectedReservation = reservation;
    this.displayDialog = true;
  }
}
