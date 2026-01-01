import { Component, OnInit, inject } from '@angular/core';
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
import { ReservationsService } from '../core/services/reservations.service';
import { MessageService } from 'primeng/api';
import { ToastModule } from 'primeng/toast';

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
    HeaderComponent,
    ToastModule
  ],
  providers: [MessageService],
  templateUrl: './reservations.component.html',
  styleUrl: './reservations.component.scss'
})
export class ReservationsComponent implements OnInit {
  private reservationsService = inject(ReservationsService);
  private messageService = inject(MessageService);

  selectedVenue = 'All Venues';
  selectedDate: Date = new Date();
  selectedStatus = 'All Status';
  selectedType = 'All Types';
  
  displayDialog = false;
  selectedReservation: any = null;

  venues = ['All Venues']; 
  
  typeOptions = [
    { label: 'All Types', value: 'All Types' },
    { label: 'Book Now', value: 'IMMEDIATE' },
    { label: 'Book for Later', value: 'SCHEDULED' }
  ];

  statusOptions = [
    { label: 'All Status', value: 'All Status' },
    { label: 'Active', value: 'active' },
    { label: 'Completed', value: 'completed' },
    { label: 'Cancelled', value: 'cancelled' }
  ];

  reservations: any[] = [];
  
  loading = true;

  // Stats for the dashboard cards
  stats = {
    todayCheckins: 0,
    occupancyRate: 0,
    occupiedSpots: 0,
    totalSpots: 500, // Hardcoded capacity for now
    pending: 0
  };

  ngOnInit() {
    this.loadReservations();
  }

  loadReservations() {
    this.loading = true;
    this.reservationsService.getReservations().subscribe({
      next: (reservations) => {
        this.reservations = reservations.map(r => {
          // Safe date parsing
          const parseDate = (dateStr: any): Date | null => {
            if (!dateStr) return null;
            const d = new Date(dateStr);
            return isNaN(d.getTime()) ? null : d;
          };

          return {
            ...r,
            user: r.user ? {
              ...r.user,
              name: r.user.name || (r.user.email ? r.user.email.split('@')[0] : 'Unknown')
            } : { name: 'Unknown User', email: 'N/A' },
            // Map API fields to UI expected fields
            vehicle: r.vehicle ? { 
              plateNumber: r.vehicle.plateNumber, 
              model: [r.vehicle.make, r.vehicle.model].filter(Boolean).join(' ') || 'Unknown' 
            } : { plateNumber: 'N/A', model: 'Unknown' },
            type: r.type, // Map the type field
            startTime: parseDate(r.startTime),
            endTime: parseDate(r.endTime),
            spotId: r.spot?.spotNumber || 'Unassigned',
            venue: r.venue?.name || 'Unknown Venue'
          };
        });
        
        this.calculateStats();
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load reservations', err);
        this.loading = false;
        this.messageService.add({ severity: 'error', summary: 'Error', detail: 'Failed to load reservations' });
      }
    });
  }

  calculateStats() {
    const today = new Date();
    const todayStr = today.toDateString();

    // Calculate Today's Check-ins (reservations starting today)
    this.stats.todayCheckins = this.reservations.filter(r => 
      new Date(r.startTime).toDateString() === todayStr
    ).length;

    // Calculate Pending Validations
    this.stats.pending = this.reservations.filter(r => r.status === 'pending').length;

    // Calculate Occupied Spots (active/checked_in status)
    this.stats.occupiedSpots = this.reservations.filter(r => 
      ['active', 'checked_in', 'confirmed'].includes(r.status)
    ).length;

    // Calculate Occupancy Rate
    this.stats.occupancyRate = Math.round((this.stats.occupiedSpots / this.stats.totalSpots) * 100);
  }

  get filteredReservations() {
    return this.reservations.filter(r => {
      const matchesVenue = this.selectedVenue === 'All Venues' || r.venue === this.selectedVenue;
      const matchesStatus = this.selectedStatus === 'All Status' || 
        (this.selectedStatus === 'active' && ['confirmed', 'checked_in'].includes(r.status)) ||
        r.status === this.selectedStatus;
      const matchesType = this.selectedType === 'All Types' || r.type === this.selectedType;
      
      return matchesVenue && matchesStatus && matchesType;
    });
  }

  showDetails(reservation: any) {
    this.selectedReservation = reservation;
    this.displayDialog = true;
  }

  getStatusColor(status: string) {
    switch (status) {
      case 'confirmed':
      case 'checked_in':
      case 'active':
        return 'border-green-200 bg-green-50 text-green-700 dark:border-green-900/50 dark:bg-green-900/20 dark:text-green-400';
      case 'completed':
        return 'border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-900/50 dark:bg-blue-900/20 dark:text-blue-400';
      case 'cancelled':
        return 'border-red-200 bg-red-50 text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400';
      case 'pending':
        return 'border-yellow-200 bg-yellow-50 text-yellow-700 dark:border-yellow-900/50 dark:bg-yellow-900/20 dark:text-yellow-400';
      default:
        return 'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400';
    }
  }
}
