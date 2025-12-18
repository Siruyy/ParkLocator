import { Component, OnInit, OnDestroy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { ChartModule } from 'primeng/chart';
import { ButtonModule } from 'primeng/button';
import { DashboardService } from '../core/services/dashboard.service';
import { interval, Subscription } from 'rxjs';

interface Alert {
  title: string;
  message: string;
  severity: 'critical' | 'warning' | 'info';
  action: string;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule, 
    RouterModule, 
    SidebarComponent, 
    HeaderComponent,
    ChartModule,
    ButtonModule
  ],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit, OnDestroy {
  private dashboardService = inject(DashboardService);
  private refreshSubscription?: Subscription;

  // Data properties
  occupancyRate = 0;
  totalOccupied = 0;
  totalCapacity = 0;
  occupancyTrend = 0;
  activeReservations = 0;
  todaysRevenue = 0;
  revenueTrend = 0;
  recentActivities: any[] = [];
  alerts: Alert[] = [];
  
  // Date/Time
  currentDate = new Date();
  lastUpdated = new Date();

  // Chart
  chartPeriod: '24h' | '7d' = '24h';
  occupancyChartData: any;
  chartOptions: any;

  loading = true;

  ngOnInit() {
    this.initChartOptions();
    this.loadStats();
    this.loadOccupancyChart();
    
    // Auto-refresh every 30 seconds
    this.refreshSubscription = interval(30000).subscribe(() => {
      this.loadStats();
    });
  }

  ngOnDestroy() {
    this.refreshSubscription?.unsubscribe();
  }

  loadStats() {
    this.loading = true;
    this.dashboardService.getStats().subscribe({
      next: (data) => {
        this.occupancyRate = data.occupancyRate;
        this.activeReservations = data.activeReservations;
        this.todaysRevenue = data.todaysRevenue;
        this.recentActivities = data.recentActivities;
        
        // Use capacity data from API
        this.totalOccupied = data.totalOccupied || 0;
        this.totalCapacity = data.totalCapacity || 0;
        
        // Mock trends for now (could be added to API later)
        this.occupancyTrend = Math.floor(Math.random() * 10) - 3; // -3 to +7
        this.revenueTrend = Math.floor(Math.random() * 20) - 5; // -5 to +15
        
        // Generate alerts based on occupancy
        this.generateAlerts();
        
        this.lastUpdated = new Date();
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load dashboard stats', err);
        this.loading = false;
      }
    });
  }

  generateAlerts() {
    this.alerts = [];
    
    if (this.occupancyRate >= 90) {
      this.alerts.push({
        title: 'High Occupancy Alert',
        message: `Parking is at ${this.occupancyRate}% capacity. Consider redirecting traffic.`,
        severity: 'critical',
        action: 'MANAGE'
      });
    }
    
    if (this.occupancyRate >= 75 && this.occupancyRate < 90) {
      this.alerts.push({
        title: 'Moderate Occupancy',
        message: `Parking is at ${this.occupancyRate}% capacity. Monitor closely.`,
        severity: 'warning',
        action: 'VIEW'
      });
    }
  }

  initChartOptions() {
    this.chartOptions = {
      maintainAspectRatio: false,
      responsive: true,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          callbacks: {
            label: (context: any) => `${context.parsed.y}% occupancy`
          }
        }
      },
      scales: {
        x: {
          ticks: {
            color: '#9ca3af',
            font: { size: 10 }
          },
          grid: {
            display: false
          }
        },
        y: {
          min: 0,
          max: 100,
          ticks: {
            color: '#9ca3af',
            font: { size: 10 },
            callback: (value: number) => `${value}%`
          },
          grid: {
            color: 'rgba(156, 163, 175, 0.1)',
            drawBorder: false
          }
        }
      },
      interaction: {
        intersect: false,
        mode: 'index'
      }
    };
  }

  setChartPeriod(period: '24h' | '7d') {
    this.chartPeriod = period;
    this.loadOccupancyChart();
  }

  loadOccupancyChart() {
    // Generate mock hourly data for now
    // This could be replaced with actual API call
    let labels: string[];
    let data: number[];
    
    if (this.chartPeriod === '24h') {
      labels = Array.from({ length: 24 }, (_, i) => {
        const hour = i.toString().padStart(2, '0');
        return `${hour}:00`;
      });
      // Mock data - simulate typical parking pattern
      data = labels.map((_, i) => {
        // Low at night, peak during work hours
        if (i >= 0 && i <= 5) return Math.floor(Math.random() * 20) + 5;
        if (i >= 6 && i <= 8) return Math.floor(Math.random() * 30) + 30;
        if (i >= 9 && i <= 17) return Math.floor(Math.random() * 20) + 60;
        if (i >= 18 && i <= 20) return Math.floor(Math.random() * 30) + 40;
        return Math.floor(Math.random() * 20) + 15;
      });
    } else {
      // Last 7 days
      labels = Array.from({ length: 7 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (6 - i));
        return date.toLocaleDateString('en-US', { weekday: 'short' });
      });
      data = labels.map(() => Math.floor(Math.random() * 40) + 40);
    }

    this.occupancyChartData = {
      labels,
      datasets: [
        {
          label: 'Occupancy',
          data,
          fill: true,
          borderColor: '#f9f506',
          borderWidth: 3,
          tension: 0.4,
          pointRadius: 0,
          pointHoverRadius: 6,
          pointHoverBackgroundColor: '#1c1c0d',
          pointHoverBorderColor: '#f9f506',
          pointHoverBorderWidth: 2,
          backgroundColor: (context: any) => {
            const ctx = context.chart.ctx;
            const gradient = ctx.createLinearGradient(0, 0, 0, 300);
            gradient.addColorStop(0, 'rgba(249, 245, 6, 0.3)');
            gradient.addColorStop(1, 'rgba(249, 245, 6, 0.0)');
            return gradient;
          }
        }
      ]
    };
  }
}
