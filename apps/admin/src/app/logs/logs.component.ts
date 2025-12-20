import { Component, OnInit, OnDestroy, inject } from '@angular/core';
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
import { AuthService } from '../core/services/auth.service';
import { VenuesService } from '../core/services/venues.service';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';

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
export class LogsComponent implements OnInit, OnDestroy {
  private financeService = inject(FinanceService);
  public authService = inject(AuthService);
  private venuesService = inject(VenuesService);

  private searchSubject = new Subject<string>();
  private searchSubscription?: Subscription;

  logs: Log[] = [];
  loading = true;
  totalRecords = 0;
  pageSize = 20;
  pageSizeOptions = [10, 20, 50, 100];
  currentPage = 1;
  protected readonly Math = Math;
  
  activeTab: 'qr' | 'admin' = 'qr';
  selectedVenue: string = 'All Venues';
  searchTerm = '';
  
  detailsVisible: boolean = false;
  selectedLog: any = null;

  venues = ['All Venues'];

  qrLogs: any[] = [];
  adminLogs: any[] = [];

  ngOnInit() {
    this.loadLogs({ first: 0, rows: this.pageSize });
    this.loadVenues();
    
    // Setup search debounce
    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(term => {
      this.searchTerm = term;
      this.onSearch();
    });

    // Hide Admin Logs tab for non-super admins
    if (this.authService.currentUser()?.role !== 'super_admin') {
      this.activeTab = 'qr';
    } else {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
    }
  }

  ngOnDestroy() {
    this.searchSubscription?.unsubscribe();
  }

  loadVenues() {
    if (this.authService.currentUser()?.role === 'super_admin') {
      this.venuesService.getVenues().subscribe(venues => {
        this.venues = ['All Venues', ...venues.map(v => v.name)];
      });
    }
  }

  onSearchInput(term: string) {
    this.searchSubject.next(term);
  }

  onSearch() {
    this.currentPage = 1;
    if (this.activeTab === 'qr') {
      this.loadLogs({ first: 0, rows: this.pageSize });
    } else {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
    }
  }

  onPageSizeChange() {
    this.loadLogs({ first: 0, rows: this.pageSize });
    if (this.authService.currentUser()?.role === 'super_admin') {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
    }
  }

  get totalPages(): number {
    return Math.ceil(this.totalRecords / this.pageSize);
  }

  get pages(): number[] {
    const total = this.totalPages;
    let start = Math.max(1, this.currentPage - 2);
    let end = Math.min(total, start + 4);
    
    if (end - start < 4) {
      start = Math.max(1, end - 4);
    }
    
    return Array.from({length: end - start + 1}, (_, i) => start + i);
  }

  loadLogs(event: any) {
    this.loading = true;
    this.currentPage = (event.first / event.rows) + 1;
    
    this.financeService.getLogs(this.currentPage, event.rows, this.searchTerm).subscribe(response => {
      this.logs = response.data;
      
      // Map API logs to QR Logs format for display
      this.qrLogs = this.logs.map(log => {
        const parts = log.details.split(' at ');
        const venueName = parts[1] || 'Unknown';
        const idPart = parts[0].split(' ');
        const id = idPart[idPart.length - 1]; // Get the last part which is the ID

        return {
          timestamp: new Date(log.timestamp).toLocaleString(),
          venue: venueName,
          gateId: this.getGateId(log.status),
          reservationId: id,
          result: ['confirmed', 'checked_in', 'completed'].includes(log.status) ? 'PASS' : 'FAIL',
          reason: log.action,
          originalLog: log
        };
      });

      this.totalRecords = response.meta.total;
      this.loading = false;
    });
  }

  loadAuditLogs(event: any) {
    this.financeService.getAuditLogs(this.currentPage, event.rows, this.searchTerm).subscribe(response => {
      this.adminLogs = response.data.map(log => ({
        user: {
          name: log.user?.email || 'System',
          initials: (log.user?.email || 'S').substring(0, 2).toUpperCase(),
          color: 'blue',
          role: log.user?.role || 'System'
        },
        venue: 'N/A', // Audit logs might not always be tied to a venue directly in this view
        action: log.action,
        details: log.details,
        timestamp: new Date(log.createdAt).toLocaleString(),
        entity: log.resourceType,
        severity: 'info',
        originalLog: log
      }));
    });
  }

  getGateId(status: string): string {
    if (status === 'checked_in') return 'Entry Gate';
    if (status === 'completed') return 'Exit Gate';
    return 'Main Gate';
  }

  showDetails(log: any) {
    const original = log.originalLog || log;
    
    // Normalize for dialog display since API data structure differs from Mock data
    this.selectedLog = {
        ...original,
        user: typeof original.user === 'string' ? {
            name: original.user,
            initials: original.user.substring(0, 2).toUpperCase(),
            color: 'blue',
            role: 'User'
        } : original.user,
        entity: original.entity || 'Reservation',
        changes: original.changes || []
    };
    
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
