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

export interface AuditLog {
  id: string;
  action: string;
  details: string;
  resourceType: string;
  resourceId: string;
  createdAt: string;
  user?: {
    email: string;
    role: string;
    name?: string;
  };
  changes?: any[];
}

@Injectable({
  providedIn: 'root'
})
export class FinanceService {
  private readonly apiUrl = `${environment.apiUrl}/reports`;

  constructor(private http: HttpClient) {}

  getSummary(): Observable<FinanceSummary> {
    return this.http.get<FinanceSummary>(`${this.apiUrl}/summary`);
  }

  getRevenueStats(period: 'day' | 'month' = 'day'): Observable<RevenueStat[]> {
    return this.http.get<RevenueStat[]>(`${this.apiUrl}/revenue`, {
      params: new HttpParams().set('period', period)
    });
  }

  getTransactions(page: number = 1, limit: number = 10, search?: string): Observable<{ data: Transaction[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    return this.http.get<{ data: Transaction[]; meta: any }>(`${this.apiUrl}/transactions`, { params });
  }

  getLogs(page: number = 1, limit: number = 20, search?: string): Observable<{ data: Log[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    return this.http.get<{ data: Log[]; meta: any }>(`${this.apiUrl}/logs`, { params });
  }

  getAuditLogs(page: number = 1, limit: number = 20, search?: string, action?: string): Observable<{ data: AuditLog[]; meta: any }> {
    let params = new HttpParams().set('page', page).set('limit', limit);
    if (search) {
      params = params.set('search', search);
    }
    if (action) {
      params = params.set('action', action);
    }
    return this.http.get<{ data: AuditLog[]; meta: any }>(`${this.apiUrl}/audit-logs`, { params });
  }
}
