import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface RevenueStat {
  date: string;
  revenue: number;
}

export interface FinanceSummary {
  totalRevenue: number;
  totalTransactions: number;
  dailyAverageRevenue: number;
  avgTicketSize: number;
  trends?: {
    revenue: number;
    transactions: number;
  };
}

export interface Transaction {
  id: string;
  amount: number;
  status: string;
  createdAt: string;
  paymentMethod?: string;
  user?: { email: string };
  venue?: { name: string };
  level?: { name: string };
  spot?: { spotNumber: string };
}

export interface Log {
  id: string;
  action: string;
  details: string;
  user: string;
  timestamp: string;
  status: string;
}

@Injectable({
  providedIn: 'root'
})
export class FinanceService {
  private readonly apiUrl = `${environment.apiUrl}/reports`;

  constructor(private http: HttpClient) {}

  getSummary(): Observable<{ success: boolean; data: FinanceSummary }> {
    return this.http.get<{ success: boolean; data: FinanceSummary }>(`${this.apiUrl}/summary`);
  }

  getRevenueStats(period: 'day' | 'month' = 'day'): Observable<{ success: boolean; data: RevenueStat[] }> {
    return this.http.get<{ success: boolean; data: RevenueStat[] }>(`${this.apiUrl}/revenue`, {
      params: new HttpParams().set('period', period)
    });
  }

  getTransactions(page: number = 1, limit: number = 10, search?: string): Observable<{ success: boolean; data: Transaction[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    return this.http.get<{ success: boolean; data: Transaction[]; meta: any }>(`${this.apiUrl}/transactions`, { params });
  }

  getLogs(page: number = 1, limit: number = 20, search?: string): Observable<{ success: boolean; data: Log[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    return this.http.get<{ success: boolean; data: Log[]; meta: any }>(`${this.apiUrl}/logs`, { params });
  }

  getAuditLogs(page: number = 1, limit: number = 20, search?: string, action?: string): Observable<{ success: boolean; data: any[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    if (action) {
      params = params.set('action', action);
    }
    return this.http.get<{ success: boolean; data: any[]; meta: any }>(`${this.apiUrl}/audit-logs`, { params });
  }
}
