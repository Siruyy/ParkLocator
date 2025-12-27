import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';
import { VenuesService } from './venues.service';

export interface ActivityLog {
  action: string;
  details: string;
  page?: string;
  element?: string;
  venueId?: string;
  venueName?: string;
  metadata?: Record<string, any>;
}

@Injectable({
  providedIn: 'root'
})
export class ActivityTrackerService {
  private readonly apiUrl = `${environment.apiUrl}/audit`;
  private http = inject(HttpClient);
  private router = inject(Router);
  private authService = inject(AuthService);

  private lastPage = '';

  constructor() {
    this.trackNavigation();
  }

  /**
   * Track page navigation automatically
   */
  private trackNavigation() {
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event: NavigationEnd) => {
      if (this.authService.currentUser() && event.urlAfterRedirects !== this.lastPage) {
        this.lastPage = event.urlAfterRedirects;
        
        // Extract venue info from URL if present
        const venueInfo = this.extractVenueFromUrl(event.urlAfterRedirects);
        
        this.log({
          action: 'PAGE_VIEW',
          details: `Navigated to ${this.getPageName(event.urlAfterRedirects)}`,
          page: event.urlAfterRedirects,
          venueId: venueInfo?.id,
          venueName: venueInfo?.name
        });
      }
    });
  }

  /**
   * Extract venue ID from URL and fetch venue name
   */
  private extractVenueFromUrl(url: string): { id: string; name?: string } | null {
    // Match URLs like /venues/{uuid}/rates or /venues/{uuid}
    const venueMatch = url.match(/\/venues\/([a-f0-9-]{36})/);
    if (venueMatch) {
      const venueId = venueMatch[1];
      // Store venue ID, name will be fetched async if needed
      return { id: venueId };
    }
    return null;
  }

  /**
   * Log a user activity
   */
  log(activity: ActivityLog): void {
    if (!this.authService.currentUser()) return;

    this.http.post(`${this.apiUrl}/activity`, activity).subscribe({
      error: (err) => console.warn('Failed to log activity:', err)
    });
  }

  /**
   * Track button clicks
   */
  trackClick(elementName: string, details?: string, metadata?: Record<string, any>): void {
    this.log({
      action: 'BUTTON_CLICK',
      details: details || `Clicked ${elementName}`,
      element: elementName,
      metadata
    });
  }

  /**
   * Track form submissions
   */
  trackFormSubmit(formName: string, details?: string): void {
    this.log({
      action: 'FORM_SUBMIT',
      details: details || `Submitted ${formName} form`,
      element: formName
    });
  }

  /**
   * Track menu selections
   */
  trackMenuSelect(menuItem: string): void {
    this.log({
      action: 'MENU_SELECT',
      details: `Selected menu item: ${menuItem}`,
      element: menuItem
    });
  }

  /**
   * Track dialog opens
   */
  trackDialogOpen(dialogName: string): void {
    this.log({
      action: 'DIALOG_OPEN',
      details: `Opened dialog: ${dialogName}`,
      element: dialogName
    });
  }

  /**
   * Track exports
   */
  trackExport(exportType: string, details?: string): void {
    this.log({
      action: 'EXPORT',
      details: details || `Exported ${exportType}`,
      element: exportType
    });
  }

  /**
   * Track filter changes
   */
  trackFilterChange(filterName: string, value: any): void {
    this.log({
      action: 'FILTER_CHANGE',
      details: `Changed filter ${filterName} to ${value}`,
      element: filterName,
      metadata: { filterValue: value }
    });
  }

  /**
   * Convert URL to readable page name
   */
  private getPageName(url: string): string {
    const pathMap: Record<string, string> = {
      '/dashboard': 'Dashboard',
      '/users': 'Users Management',
      '/venues': 'Venues Management',
      '/reservations': 'Reservations',
      '/finance': 'Finance & Reports',
      '/logs': 'System Logs',
      '/profile': 'Profile Settings',
      '/login': 'Login Page'
    };

    // Check for venue-specific pages
    if (url.match(/\/venues\/[a-f0-9-]+\/rates/)) {
      return 'Venue Rate Management';
    }
    if (url.match(/\/venues\/[a-f0-9-]+/)) {
      return 'Venue Configuration';
    }

    for (const [path, name] of Object.entries(pathMap)) {
      if (url.startsWith(path)) return name;
    }

    return url;
  }
}
