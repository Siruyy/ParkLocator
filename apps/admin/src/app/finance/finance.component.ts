import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { ChartModule } from 'primeng/chart';
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { Select } from 'primeng/select';
import { FinanceService, RevenueStat, Transaction, FinanceSummary } from '../core/services/finance.service';

@Component({
  selector: 'app-finance',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule,
    SidebarComponent, 
    HeaderComponent,
    ChartModule,
    TableModule,
    ButtonModule,
    Select
  ],
  templateUrl: './finance.component.html',
  styleUrl: './finance.component.scss'
})
export class FinanceComponent implements OnInit {
  protected readonly Math = Math;
  private financeService = inject(FinanceService);

  // Summary Data
  summary: FinanceSummary | null = null;

  // Chart Data
  revenueData: any;
  chartOptions: any;
  currentPeriod: 'day' | 'month' = 'day';

  // Table Data
  transactions: Transaction[] = [];
  loading = true;
  totalRecords = 0;
  pageSize = 5;
  pageSizeOptions = [5, 10, 20, 50];
  currentPage = 1;
  searchTerm = '';

  ngOnInit() {
    this.loadSummary();
    this.initChartOptions();
    this.loadRevenueData(this.currentPeriod);
    this.loadTransactions(1);
  }

  setPeriod(period: 'day' | 'month') {
    this.currentPeriod = period;
    this.loadRevenueData(period);
  }

  onPageSizeChange() {
    this.currentPage = 1;
    this.loadTransactions(1);
  }

  onSearch() {
    this.currentPage = 1;
    this.loadTransactions(1);
  }

  loadSummary() {
    this.financeService.getSummary().subscribe(response => {
      this.summary = response.data;
    });
  }

  initChartOptions() {
    const documentStyle = getComputedStyle(document.documentElement);
    const textColor = documentStyle.getPropertyValue('--text-color');
    const textColorSecondary = documentStyle.getPropertyValue('--text-color-secondary');
    const surfaceBorder = documentStyle.getPropertyValue('--surface-border');

    this.chartOptions = {
      maintainAspectRatio: false,
      responsive: true,
      plugins: {
        legend: {
          labels: {
            color: textColor
          }
        }
      },
      scales: {
        x: {
          ticks: {
            color: textColorSecondary
          },
          grid: {
            color: surfaceBorder,
            drawBorder: false
          }
        },
        y: {
          ticks: {
            color: textColorSecondary
          },
          grid: {
            color: surfaceBorder,
            drawBorder: false
          }
        }
      }
    };
  }

  loadRevenueData(period: 'day' | 'month') {
    this.financeService.getRevenueStats(period).subscribe(response => {
      const stats = response.data;
      
      this.revenueData = {
        labels: stats.map(s => s.date),
        datasets: [
          {
            label: period === 'day' ? 'Daily Revenue' : 'Monthly Revenue',
            data: stats.map(s => s.revenue),
            fill: true,
            borderColor: '#4CAF50',
            tension: 0.4,
            backgroundColor: (context: any) => {
              const ctx = context.chart.ctx;
              const gradient = ctx.createLinearGradient(0, 0, 0, 400);
              gradient.addColorStop(0, 'rgba(76, 175, 80, 0.2)');
              gradient.addColorStop(1, 'rgba(76, 175, 80, 0.0)');
              return gradient;
            }
          }
        ]
      };
    });
  }

  loadTransactions(page: number) {
    this.loading = true;
    this.currentPage = page;
    
    this.financeService.getTransactions(page, this.pageSize, this.searchTerm).subscribe(response => {
      this.transactions = response.data;
      this.totalRecords = response.meta.total;
      this.loading = false;
    });
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

  exportCSV() {
    // Simple CSV export implementation
    const headers = ['ID', 'Date', 'User', 'Venue', 'Amount', 'Status'];
    const rows = this.transactions.map(t => [
      t.id,
      new Date(t.createdAt).toLocaleString(),
      t.user?.email || 'N/A',
      t.venue?.name || 'N/A',
      t.amount,
      t.status
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `transactions-${new Date().toISOString()}.csv`;
    a.click();
  }
}
