import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { DialogModule } from 'primeng/dialog';
import { ButtonModule } from 'primeng/button';
import { Select } from 'primeng/select';
import { FinanceService, Log } from '../core/services/finance.service';

@Component({
  selector: 'app-logs',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule,
    SidebarComponent, 
    HeaderComponent,
    TableModule,
    TagModule,
    DialogModule,
    ButtonModule,
    Select
  ],
  templateUrl: './logs.component.html',
  styleUrl: './logs.component.scss'
})
export class LogsComponent implements OnInit {
  private financeService = inject(FinanceService);

  logs: Log[] = [];
  loading = true;
  totalRecords = 0;
  pageSize = 20;
  
  activeTab: 'qr' | 'admin' = 'qr';
  selectedVenue: string = 'All Venues';
  
  detailsVisible: boolean = false;
  selectedLog: any = null;

  venues = ['All Venues', 'SM Megamall', 'Glorietta 4', 'Greenbelt 3', 'Trinoma'];

  // Mock data for UI demonstration
  qrLogs = [
    { timestamp: 'Oct 24, 14:30:15', venue: 'SM Megamall', gateId: 'Gate-North-1', reservationId: '#RES-9982', result: 'PASS', reason: 'Authorized Entry' },
    { timestamp: 'Oct 24, 14:15:22', venue: 'Glorietta 4', gateId: 'Gate-South-2', reservationId: '#RES-9901', result: 'FAIL', reason: 'Invalid Time Window' },
    { timestamp: 'Oct 24, 13:55:04', venue: 'SM Megamall', gateId: 'Gate-North-1', reservationId: '#RES-8822', result: 'PASS', reason: 'Authorized Entry' },
    { timestamp: 'Oct 24, 13:12:45', venue: 'Trinoma', gateId: 'Gate-West-3', reservationId: 'UNKNOWN', result: 'FAIL', reason: 'QR Code Unreadable' },
    { timestamp: 'Oct 24, 12:45:10', venue: 'Greenbelt 3', gateId: 'Gate-South-2', reservationId: '#RES-9800', result: 'PASS', reason: 'Authorized Entry' },
  ];

  adminLogs = [
    { 
      user: { name: 'Juan Dela Cruz', role: 'Manager', initials: 'JD', color: 'blue' }, 
      venue: 'SM Megamall',
      action: 'Updated Venue Config', 
      details: 'Changed Gate 1 closing time', 
      timestamp: 'Oct 24, 10:00:00 AM', 
      entity: 'Venue Settings',
      severity: 'info',
      changes: [
        { field: 'Gate 1 Closing Time', before: '22:00', after: '23:00' },
        { field: 'Weekend Rates', before: '₱50.00', after: '₱60.00' }
      ]
    },
    { 
      user: { name: 'Maria Santos', role: 'Attendant', initials: 'MS', color: 'green' }, 
      venue: 'Glorietta 4',
      action: 'Manual Gate Override', 
      details: 'Opened barrier for emergency vehicle', 
      timestamp: 'Oct 24, 09:42:12 AM', 
      entity: 'Gate-North-1',
      severity: 'warning',
      changes: null // No diff for this action
    },
    { 
      user: { name: 'Juan Dela Cruz', role: 'Manager', initials: 'JD', color: 'orange' }, 
      venue: 'SM Megamall',
      action: 'User Role Updated', 
      details: 'Promoted r.diaz to Senior Attendant', 
      timestamp: 'Oct 23, 16:15:33 PM', 
      entity: 'User: r.diaz',
      severity: 'success',
      changes: [
        { field: 'Role', before: 'Attendant', after: 'Senior Attendant' },
        { field: 'Permissions', before: 'Read-Only', after: 'Read-Write' }
      ]
    },
  ];

  ngOnInit() {
    this.loadLogs({ first: 0, rows: 20 });
  }

  loadLogs(event: any) {
    this.loading = true;
    const page = (event.first / event.rows) + 1;
    
    this.financeService.getLogs(page, event.rows).subscribe(response => {
      this.logs = response.data;
      this.totalRecords = response.meta.total;
      this.loading = false;
    });
  }

  showDetails(log: any) {
    this.selectedLog = log;
    this.detailsVisible = true;
  }

  getSeverity(status: string) {
    switch (status) {
      case 'confirmed':
      case 'checked_in':
      case 'completed':
        return 'success';
      case 'pending':
        return 'warn';
      case 'cancelled':
        return 'danger';
      default:
        return 'info';
    }
  }
}
