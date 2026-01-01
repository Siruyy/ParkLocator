import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Reservation {
  id: string;
  user: {
    id: string;
    email: string;
    role: string;
    name?: string;
  };
  venue: {
    id: string;
    name: string;
  };
  level: {
    id: string;
    name: string;
  };
  spot: {
    id: string;
    name: string;
    spotNumber: string;
  };
  type: 'IMMEDIATE' | 'SCHEDULED';
  vehicle?: {
    id: string;
    plateNumber: string;
    make: string;
    model: string;
  };
  startTime: string;
  endTime: string;
  status: 'pending' | 'confirmed' | 'checked_in' | 'completed' | 'cancelled';
  amount: number;
  qrCode: string;
  createdAt: string;
  updatedAt: string;
}

export interface ReservationsResponse {
  success: boolean;
  data: Reservation[];
  meta: {
    count: number;
  };
}

@Injectable({
  providedIn: 'root'
})
export class ReservationsService {
  private readonly apiUrl = `${environment.apiUrl}/reservations`;

  constructor(private http: HttpClient) {}

  getReservations(): Observable<Reservation[]> {
    return this.http.get<{ data: Reservation[], meta: any }>(`${this.apiUrl}/admin/all`).pipe(
      map(response => response.data)
    );
  }

  cancelReservation(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
}
