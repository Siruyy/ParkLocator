import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap, catchError, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface User {
  id: string;
  email: string;
  role: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
}

export interface AuthResponse {
  access_token: string;
  user: User;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
}

const TOKEN_KEY = 'parklocator_token';
const USER_KEY = 'parklocator_user';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly apiUrl = `${environment.apiUrl}/auth`;
  
  // Signals for reactive state
  private currentUserSignal = signal<User | null>(this.loadUserFromStorage());
  private isLoadingSignal = signal<boolean>(false);
  private errorSignal = signal<string | null>(null);

  // Public computed signals
  readonly currentUser = computed(() => this.currentUserSignal());
  readonly isAuthenticated = computed(() => !!this.currentUserSignal());
  readonly isLoading = computed(() => this.isLoadingSignal());
  readonly error = computed(() => this.errorSignal());

  constructor(
    private http: HttpClient,
    private router: Router
  ) {
    // Check token validity on service init
    this.checkAuthState();
  }

  private loadUserFromStorage(): User | null {
    const userJson = localStorage.getItem(USER_KEY);
    if (userJson) {
      try {
        return JSON.parse(userJson);
      } catch {
        return null;
      }
    }
    return null;
  }

  private checkAuthState(): void {
    const token = this.getToken();
    if (!token) {
      this.clearAuth();
    }
  }

  getToken(): string | null {
    return localStorage.getItem(TOKEN_KEY);
  }

  login(credentials: LoginRequest): Observable<AuthResponse> {
    this.isLoadingSignal.set(true);
    this.errorSignal.set(null);

    return this.http.post<AuthResponse>(`${this.apiUrl}/login`, credentials).pipe(
      tap(response => {
        this.handleAuthSuccess(response);
        this.isLoadingSignal.set(false);
      }),
      catchError(error => {
        this.isLoadingSignal.set(false);
        const message = error.error?.message || 'Login failed. Please try again.';
        this.errorSignal.set(message);
        return throwError(() => error);
      })
    );
  }

  register(data: RegisterRequest): Observable<AuthResponse> {
    this.isLoadingSignal.set(true);
    this.errorSignal.set(null);

    return this.http.post<AuthResponse>(`${this.apiUrl}/register`, data).pipe(
      tap(response => {
        this.handleAuthSuccess(response);
        this.isLoadingSignal.set(false);
      }),
      catchError(error => {
        this.isLoadingSignal.set(false);
        const message = error.error?.message || 'Registration failed. Please try again.';
        this.errorSignal.set(message);
        return throwError(() => error);
      })
    );
  }

  private handleAuthSuccess(response: AuthResponse): void {
    localStorage.setItem(TOKEN_KEY, response.access_token);
    localStorage.setItem(USER_KEY, JSON.stringify(response.user));
    this.currentUserSignal.set(response.user);
  }

  logout(): void {
    this.clearAuth();
    this.router.navigate(['/login']);
  }

  private clearAuth(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this.currentUserSignal.set(null);
  }

  clearError(): void {
    this.errorSignal.set(null);
  }
}
