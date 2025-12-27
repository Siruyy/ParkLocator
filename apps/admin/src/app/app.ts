import { Component, signal, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ActivityTrackerService } from './core/services/activity-tracker.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App {
  protected readonly title = signal('admin');
  
  // Initialize activity tracker for navigation tracking
  private activityTracker = inject(ActivityTrackerService);
}
