import { Injectable, signal, computed } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface User {
  id: string;
  email: string;
  role: 'super_admin' | 'driver' | 'manager' | 'attendant';
  status: 'active' | 'inactive' | 'locked';
  firstName?: string;
  lastName?: string;
  phone?: string;
  createdAt: string;
  updatedAt: string;
  venue?: {
    id: string;
    name: string;
  };
  employeeId?: string;
  department?: string;
  location?: string;
  avatarUrl?: string;
}

export interface PaginatedUsers {
  data: User[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export interface QueryUsersDto {
  search?: string;
  role?: string;
  status?: string;
  venueId?: string;
  page?: number;
  limit?: number;
}

@Injectable({
  providedIn: 'root'
})
export class UsersService {
  private readonly apiUrl = `${environment.apiUrl}/users`;

  constructor(private http: HttpClient) {}

  getUsers(query: QueryUsersDto = {}): Observable<PaginatedUsers> {
    let params = new HttpParams();
    if (query.search) params = params.set('search', query.search);
    if (query.role) params = params.set('role', query.role);
    if (query.status) params = params.set('status', query.status);
    if (query.venueId) params = params.set('venueId', query.venueId);
    if (query.page) params = params.set('page', query.page);
    if (query.limit) params = params.set('limit', query.limit);

    return this.http.get<PaginatedUsers>(this.apiUrl, { params });
  }

  updateRole(id: string, role: string): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}/role`, { role });
  }

  updateStatus(id: string, status: string): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}/status`, { status });
  }

  createUser(user: Partial<User>): Observable<User> {
    return this.http.post<User>(this.apiUrl, user);
  }

  updateUser(id: string, user: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}`, user);
  }

  updateProfile(user: Partial<User>): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/profile`, user);
  }

  changePassword(password: string): Observable<void> {
    return this.http.patch<void>(`${this.apiUrl}/profile/password`, { password });
  }

  uploadAvatar(file: File): Observable<User> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<User>(`${this.apiUrl}/profile/avatar`, formData);
  }

  deleteUser(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
