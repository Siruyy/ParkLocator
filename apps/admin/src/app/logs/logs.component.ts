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
  
  activeTab: 'qr' | 'admin' | 'venues' = 'qr';
  selectedVenue: string = 'All Venues';
  searchTerm = '';
  
  detailsVisible: boolean = false;
  selectedLog: any = null;

  venues = ['All Venues'];
  private venueMap: Map<string, string> = new Map(); // venueId -> venueName

  qrLogs: any[] = [];
  adminLogs: any[] = [];
  venueLogs: any[] = []; // New array for venue logs

  ngOnInit() {
    this.loadLogs({ first: 0, rows: this.pageSize });
    this.loadVenues();
    
    // Setup search debounce - only debounce the API call, not the UI
    this.searchSubscription = this.searchSubject.pipe(
      debounceTime(300),
      distinctUntilChanged()
    ).subscribe(() => {
      this.performSearch();
    });

    // Hide Admin Logs tab for non-super admins
    if (this.authService.currentUser()?.role !== 'super_admin') {
      this.activeTab = 'qr';
    } else {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
      this.loadVenueLogs({ first: 0, rows: this.pageSize }); // Load venue logs
    }
  }

  ngOnDestroy() {
    this.searchSubscription?.unsubscribe();
  }

  loadVenues() {
    if (this.authService.currentUser()?.role === 'super_admin') {
      this.venuesService.getVenues().subscribe(venues => {
        this.venues = ['All Venues', ...venues.map(v => v.name)];
        // Build venue map for lookups
        venues.forEach(v => this.venueMap.set(v.id, v.name));
      });
    }
  }

  getVenueName(venueId: string | null): string {
    if (!venueId) return 'N/A';
    return this.venueMap.get(venueId) || 'N/A';
  }

  onSearchInput(term: string) {
    this.searchTerm = term; // Update immediately for responsive UI
    this.searchSubject.next(term); // Trigger debounced search
  }

  performSearch() {
    this.currentPage = 1;
    if (this.activeTab === 'qr') {
      this.loadLogs({ first: 0, rows: this.pageSize });
    } else if (this.activeTab === 'admin') {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
    } else if (this.activeTab === 'venues') {
      this.loadVenueLogs({ first: 0, rows: this.pageSize });
    }
  }

  onPageSizeChange() {
    this.currentPage = 1;
    if (this.activeTab === 'qr') {
      this.loadLogs({ first: 0, rows: this.pageSize });
    } else if (this.activeTab === 'admin') {
      this.loadAuditLogs({ first: 0, rows: this.pageSize });
    } else if (this.activeTab === 'venues') {
      this.loadVenueLogs({ first: 0, rows: this.pageSize });
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
    this.loading = true;
    this.financeService.getAuditLogs(this.currentPage, event.rows, this.searchTerm).subscribe(response => {
      this.adminLogs = response.data.map(log => {
        // Determine venue name from resourceId if resourceType is Venue
        let venueName = 'N/A';
        
        if (log.resourceType === 'Venue' && log.resourceId) {
          // Try to get venue name from map
          venueName = this.getVenueName(log.resourceId);
          
          // If not found in map, try to extract from details
          if (venueName === 'N/A' && log.details) {
            const venueMatch = log.details.match(/\[Venue: ([^\]]+)\]/);
            if (venueMatch) {
              venueName = venueMatch[1];
            }
          }
        }

        return {
          user: {
            name: log.user?.email || 'System',
            initials: (log.user?.email || 'S').substring(0, 2).toUpperCase(),
            color: this.getColorForAction(log.action),
            role: log.user?.role || 'System'
          },
          venue: venueName,
          action: this.formatAction(log.action),
          details: log.details,
          timestamp: new Date(log.createdAt).toLocaleString(),
          entity: log.resourceType,
          severity: this.getSeverityForAction(log.action),
          changes: log.changes || [],
          resourceId: log.resourceId, // Add this line
          originalLog: log
        };
      });
      if (this.activeTab === 'admin') {
        this.totalRecords = response.meta?.total || this.adminLogs.length;
      }
      this.loading = false;
    });
  }

  loadVenueLogs(event: any) {
    const page = (event.first / event.rows) + 1;
    this.financeService.getAuditLogs(page, event.rows, this.searchTerm, 'DELETE_VENUE').subscribe(response => {
      this.venueLogs = response.data.map(log => {
        return {
          user: log.user ? {
            name: log.user.name || log.user.email,
            initials: (log.user.name || log.user.email || 'U').substring(0, 2).toUpperCase(),
            color: 'orange',
            role: log.user.role || 'Admin'
          } : { name: 'System', initials: 'SY', color: 'blue', role: 'System' },
          venue: log.details.replace('Deleted venue ', ''),
          action: log.action,
          details: log.details,
          timestamp: new Date(log.createdAt).toLocaleString(),
          entity: log.resourceType,
          severity: 'warning',
          changes: log.changes || [],
          resourceId: log.resourceId,
          originalLog: log
        };
      });
      if (this.activeTab === 'venues') {
        this.totalRecords = response.meta?.total || this.venueLogs.length;
      }
      this.loading = false;
    });
  }

  getColorForAction(action: string): string {
    if (action.startsWith('DELETE') || action === 'CANCEL_RESERVATION') return 'orange';
    if (action.startsWith('CREATE') || action === 'USER_REGISTER') return 'green';
    return 'blue';
  }

  formatAction(action: string): string {
    return action.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }

  getSeverityForAction(action: string): string {
    if (action.startsWith('DELETE') || action === 'CANCEL_RESERVATION') return 'warning';
    if (action.startsWith('CREATE') || action === 'USER_REGISTER') return 'success';
    return 'info';
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
        ...log, // Include the mapped properties from loadAuditLogs
        user: log.user || (typeof original.user === 'string' ? {
            name: original.user,
            initials: original.user.substring(0, 2).toUpperCase(),
            color: 'blue',
            role: 'User'
        } : original.user) || { name: 'System', initials: 'SY', color: 'blue', role: 'System' },
        action: log.action || original.action || 'Unknown Action',
        details: log.details || original.details || '',
        timestamp: log.timestamp || (original.createdAt ? new Date(original.createdAt).toLocaleString() : ''),
        entity: log.entity || original.resourceType || 'Activity',
        resourceId: original.resourceId || null,
        ipAddress: original.ipAddress || null,
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

  restoreVenue(venueId: string) {
    if (!confirm('Are you sure you want to restore this venue?')) return;

    this.venuesService.restoreVenue(venueId).subscribe({
      next: () => {
        alert('Venue restored successfully');
        this.loadAuditLogs({ first: (this.currentPage - 1) * this.pageSize, rows: this.pageSize });
      },
      error: (err) => {
        console.error('Failed to restore venue', err);
        alert('Failed to restore venue');
      }
    });
  }
}
