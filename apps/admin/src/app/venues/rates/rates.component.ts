import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute } from '@angular/router';
import {
  FormBuilder,
  FormGroup,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { SidebarComponent } from '../../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../../layout/header/header.component';
import { VenuesService } from '../../core/services/venues.service';
import { finalize } from 'rxjs/operators';

// PrimeNG Imports
import { CardModule } from 'primeng/card';
import { InputNumberModule } from 'primeng/inputnumber';
import { ToggleSwitchModule } from 'primeng/toggleswitch';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { ConfirmDialogModule } from 'primeng/confirmdialog';
import { ConfirmationService } from 'primeng/api';
import { Observable } from 'rxjs';
import { CanComponentDeactivate } from '../../core/guards/unsaved-changes.guard';

@Component({
  selector: 'app-rates',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    ReactiveFormsModule,
    SidebarComponent,
    HeaderComponent,
    CardModule,
    InputNumberModule,
    ToggleSwitchModule,
    ButtonModule,
    InputTextModule,
    ConfirmDialogModule
  ],
  providers: [ConfirmationService],
  templateUrl: './rates.component.html',
  styleUrl: './rates.component.scss',
})
export class RatesComponent implements OnInit, CanComponentDeactivate {
  configForm: FormGroup;
  venueId: string | null = null;
  isLoading = false;
  isSaving = false;
  initialFormValue: any;

  constructor(
    private fb: FormBuilder,
    private venuesService: VenuesService,
    private route: ActivatedRoute,
    private confirmationService: ConfirmationService
  ) {
    this.configForm = this.fb.group({
      // Standard Rates
      reservationFee: [0, [Validators.required, Validators.min(0)]],
      baseRate: [40, [Validators.required, Validators.min(0)]],
      baseDuration: [1, [Validators.required, Validators.min(0)]],
      succeedingHourRate: [20, [Validators.required, Validators.min(0)]],

      // Weekend Surcharge
      weekendSurcharge: [0, [Validators.required, Validators.min(0)]],
      isWeekendSurchargeActive: [false],

      // Motorcycle Flat Rate
      motorcycleFlatRate: [30, [Validators.required, Validators.min(0)]],
      isMotorcycleFlatRateActive: [false],

      // Overnight Parking
      overnightFlatRate: [300, [Validators.required, Validators.min(0)]],
      overnightStartHour: ['22:00', Validators.required],
      overnightEndHour: ['06:00', Validators.required],
      isOvernightParkingActive: [false],

      // Limits & Grace Periods
      entryGracePeriod: [15, [Validators.required, Validators.min(0)]],
      exitGracePeriod: [10, [Validators.required, Validators.min(0)]],
      maxReservationHold: [30, [Validators.required, Validators.min(0)]],

      // Penalties
      lostTicketPenalty: [500, [Validators.required, Validators.min(0)]],
      illegalParkingPenalty: [1000, [Validators.required, Validators.min(0)]],
    });
  }

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      this.venueId = params.get('id');
      if (this.venueId) {
        this.loadConfiguration();
      }
    });
  }

  loadConfiguration(): void {
    if (!this.venueId) return;

    this.isLoading = true;
    this.venuesService
      .getVenueConfiguration(this.venueId)
      .pipe(finalize(() => (this.isLoading = false)))
      .subscribe({
        next: (config) => {
          this.configForm.patchValue(config);
          this.initialFormValue = this.configForm.getRawValue();
        },
        error: (error) => {
          console.error('Error loading configuration:', error);
          // Handle error (e.g., show toast)
        },
      });
  }

  save(): void {
    if (this.configForm.invalid) {
      this.configForm.markAllAsTouched();
      return;
    }
    
    if (!this.venueId) return;

    this.isSaving = true;
    this.venuesService
      .updateVenueConfiguration(this.venueId, this.configForm.value)
      .pipe(finalize(() => (this.isSaving = false)))
      .subscribe({
        next: (config) => {
          this.configForm.patchValue(config);
          this.initialFormValue = this.configForm.getRawValue();
          // Show success message
          alert('Configuration saved successfully');
        },
        error: (error) => {
          console.error('Error saving configuration:', error);
          alert('Failed to save configuration');
        },
      });
  }

  discardChanges(): void {
    this.confirmationService.confirm({
        message: 'Are you sure you want to discard your changes?',
        header: 'Discard Changes',
        icon: 'pi pi-exclamation-triangle',
        accept: () => {
            if (this.initialFormValue) {
                this.configForm.reset(this.initialFormValue);
            }
        }
    });
  }

  canDeactivate(): boolean | Observable<boolean> {
    if (this.configForm.dirty && JSON.stringify(this.configForm.getRawValue()) !== JSON.stringify(this.initialFormValue)) {
        return new Observable<boolean>((observer) => {
            this.confirmationService.confirm({
                message: 'You have unsaved changes. Are you sure you want to leave?',
                header: 'Unsaved Changes',
                icon: 'pi pi-exclamation-triangle',
                accept: () => {
                    observer.next(true);
                    observer.complete();
                },
                reject: () => {
                    observer.next(false);
                    observer.complete();
                }
            });
        });
    }
    return true;
  }
}
