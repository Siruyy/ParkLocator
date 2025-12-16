import { Injectable, signal, computed } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface User {
  id: string;
  email: string;
  role: 'driver' | 'manager' | 'attendant';
  createdAt: string;
  updatedAt: string;
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
    if (query.page) params = params.set('page', query.page);
    if (query.limit) params = params.set('limit', query.limit);

    return this.http.get<PaginatedUsers>(this.apiUrl, { params });
  }

  updateRole(id: string, role: string): Observable<User> {
    return this.http.patch<User>(`${this.apiUrl}/${id}/role`, { role });
  }

  deleteUser(id: string): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
