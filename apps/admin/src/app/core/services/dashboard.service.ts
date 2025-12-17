import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface DashboardStats {
  userStats: {
    totalUsers: number;
    activeNow: number;
    managers: number;
    attendants: number;
  };
  occupancyRate: number;
  occupancyData: {
    label: string;
    value: number;
    color: string;
    icon: string;
  }[];
  activeReservations: number;
  todaysRevenue: number;
  recentActivities: {
    title: string;
    time: string;
    icon: string;
    iconBg: string;
    iconColor: string;
    details: string;
  }[];
}

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  private readonly apiUrl = `${environment.apiUrl}/dashboard`;

  constructor(private http: HttpClient) {}

  getStats(): Observable<DashboardStats> {
    return this.http.get<DashboardStats>(`${this.apiUrl}/stats`);
  }
}
