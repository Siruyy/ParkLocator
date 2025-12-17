import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { TableModule } from 'primeng/table';
import { TagModule } from 'primeng/tag';
import { FinanceService, Log } from '../core/services/finance.service';

@Component({
  selector: 'app-logs',
  standalone: true,
  imports: [
    CommonModule, 
    SidebarComponent, 
    HeaderComponent,
    TableModule,
    TagModule
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
