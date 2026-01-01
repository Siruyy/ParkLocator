import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Level {
  id: string;
  levelNumber: number;
  name: string;
  totalCapacity: number;
  availableSpots: number;
  isActive: boolean;
  isCovered?: boolean;
  vehicleTypes?: string[];
  sections?: { name: string; totalCapacity: number; vehicleType?: string }[];
}

export interface Spot {
  id: string;
  spotNumber: string;
  status: 'available' | 'occupied' | 'reserved' | 'maintenance';
  isActive: boolean;
  vehicleType: string;
  levelId: string;
  section?: string;
}

export interface Venue {
  id: string;
  name: string;
  address: string;
  description: string;
  imageUrl: string;
  latitude?: number;
  longitude?: number;
  levels: Level[];
  supportsRealTimeBooking?: boolean;
  supportsFutureBooking?: boolean;
  requireVehicleDetails?: boolean;
  hasCoveredParking?: boolean;
  hasCCTV?: boolean;
}

export interface VenueConfiguration {
  reservationFee: number;
  baseRate: number;
  baseDuration: number;
  succeedingHourRate: number;
  weekendSurcharge: number;
  isWeekendSurchargeActive: boolean;
  motorcycleFlatRate: number;
  isMotorcycleFlatRateActive: boolean;
  overnightFlatRate: number;
  overnightStartHour: string;
  overnightEndHour: string;
  isOvernightParkingActive: boolean;
  entryGracePeriod: number;
  exitGracePeriod: number;
  maxReservationHold: number;
  lostTicketPenalty: number;
  illegalParkingPenalty: number;
}

interface ApiResponse<T> {
  success: boolean;
  data: T;
  meta?: any;
}

@Injectable({
  providedIn: 'root'
})
export class VenuesService {
  private readonly apiUrl = `${environment.apiUrl}/venues`;

  constructor(private http: HttpClient) {}

  getVenues(): Observable<Venue[]> {
    return this.http.get<Venue[]>(this.apiUrl).pipe(
      map(venues => venues.map(venue => this.transformVenue(venue)))
    );
  }

  getVenue(id: string): Observable<Venue> {
    return this.http.get<Venue>(`${this.apiUrl}/${id}`).pipe(
      map(venue => this.transformVenue(venue))
    );
  }

  createVenue(venue: FormData): Observable<Venue> {
    return this.http.post<Venue>(this.apiUrl, venue).pipe(
      map(venue => this.transformVenue(venue))
    );
  }

  updateVenue(id: string, venue: Partial<Venue> | FormData): Observable<Venue> {
    return this.http.patch<Venue>(`${this.apiUrl}/${id}`, venue).pipe(
      map(venue => this.transformVenue(venue))
    );
  }

  updateVenueJson(id: string, venue: Partial<Venue>): Observable<Venue> {
    return this.http.patch<ApiResponse<Venue>>(`${this.apiUrl}/${id}`, venue, {
      headers: { 'Content-Type': 'application/json' }
    }).pipe(
      map(response => this.transformVenue(response.data))
    );
  }

  private transformVenue(venue: Venue): Venue {
    if (venue.imageUrl && !venue.imageUrl.startsWith('http')) {
      const baseUrl = environment.apiUrl.replace('/api/v1', '');
      venue.imageUrl = `${baseUrl}${venue.imageUrl}`;
    }
    return venue;
  }

  deleteVenue(id: string): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`).pipe(
      map(() => void 0)
    );
  }

  restoreVenue(id: string): Observable<Venue> {
    return this.http.post<ApiResponse<Venue>>(`${this.apiUrl}/${id}/restore`, {}).pipe(
      map(response => this.transformVenue(response.data))
    );
  }



  getVenueConfiguration(venueId: string): Observable<VenueConfiguration> {
    return this.http
      .get<ApiResponse<VenueConfiguration>>(`${this.apiUrl}/${venueId}/configuration`)
      .pipe(map((response) => response.data));
  }

  updateVenueConfiguration(
    venueId: string,
    config: Partial<VenueConfiguration>
  ): Observable<VenueConfiguration> {
    return this.http
      .patch<ApiResponse<VenueConfiguration>>(
        `${this.apiUrl}/${venueId}/configuration`,
        config
      )
      .pipe(map((response) => response.data));
  }

  createLevel(venueId: string, level: Partial<Level>): Observable<Level> {
    return this.http.post<ApiResponse<Level>>(`${this.apiUrl}/${venueId}/levels`, level).pipe(
      map(response => response.data)
    );
  }

  updateLevel(levelId: string, level: Partial<Level>): Observable<Level> {
    return this.http.patch<ApiResponse<Level>>(`${environment.apiUrl}/levels/${levelId}`, level).pipe(
      map(response => response.data)
    );
  }

  deleteLevel(levelId: string): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${environment.apiUrl}/levels/${levelId}`).pipe(
      map(() => void 0)
    );
  }

  getSpots(levelId: string): Observable<Spot[]> {
    return this.http.get<ApiResponse<Level>>(`${environment.apiUrl}/levels/${levelId}`).pipe(
      map(response => (response.data as any).spots || [])
    );
  }

  updateSpotStatus(spotId: string, status: string): Observable<Spot> {
    return this.http.patch<ApiResponse<Spot>>(`${environment.apiUrl}/spots/${spotId}`, { status }).pipe(
      map(response => response.data)
    );
  }
}
