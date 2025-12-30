import { Component, OnInit, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { VenuesService, Venue } from '../core/services/venues.service';
import { AuthService } from '../core/services/auth.service';
import { ActivityTrackerService } from '../core/services/activity-tracker.service';

// PrimeNG Imports
import { TableModule } from 'primeng/table';
import { ButtonModule } from 'primeng/button';
import { DialogModule } from 'primeng/dialog';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { TooltipModule } from 'primeng/tooltip';
import { CardModule } from 'primeng/card';
import { SelectModule } from 'primeng/select';
import { IconFieldModule } from 'primeng/iconfield';
import { InputIconModule } from 'primeng/inputicon';
import { CheckboxModule } from 'primeng/checkbox';

@Component({
  selector: 'app-venues',
  standalone: true,
  imports: [
    CommonModule, 
    FormsModule, 
    ReactiveFormsModule, 
    RouterModule, 
    SidebarComponent, 
    HeaderComponent,
    TableModule,
    ButtonModule,
    DialogModule,
    InputTextModule,
    TagModule,
    TooltipModule,
    CardModule,
    SelectModule,
    IconFieldModule,
    InputIconModule,
    CheckboxModule
  ],
  templateUrl: './venues.component.html',
  styleUrl: './venues.component.scss'
})
export class VenuesComponent implements OnInit {
  private venuesService = inject(VenuesService);
  private authService = inject(AuthService);
  private fb = inject(FormBuilder);
  private route = inject(ActivatedRoute);
  private activityTracker = inject(ActivityTrackerService);

  venues: Venue[] = [];
  selectedVenue: Venue | null = null;
  selectedProperty = '';
  
  parkingLevels: any[] = [];
  
  // View Mode
  viewMode: 'list' | 'details' = 'list';
  
  // Super Admin features
  isSuperAdmin = computed(() => this.authService.currentUser()?.role === 'super_admin');
  showAddPropertyModal = false;
  isEditingProperty = false;
  editingVenueId: string | null = null;
  propertyForm: FormGroup;
  
  // Level Management
  showAddLevelModal = false;
  levelForm: FormGroup;
  isSubmitting = false;
  isSubmittingLevel = false;

  constructor() {
    this.propertyForm = this.fb.group({
      name: ['', Validators.required],
      address: ['', Validators.required],
      latitude: [14.5995, [Validators.required, Validators.min(-90), Validators.max(90)]],
      longitude: [120.9842, [Validators.required, Validators.min(-180), Validators.max(180)]],
      description: [''],
      imageUrl: [''],
      supportsRealTimeBooking: [true],
      supportsFutureBooking: [false],
      requireVehicleDetails: [true],
      hasCoveredParking: [false],
      hasCCTV: [false]
    });

    this.levelForm = this.fb.group({
      levelNumber: [1, [Validators.required, Validators.min(-10), Validators.max(100)]],
      name: ['', Validators.required],
      totalCapacity: [50, [Validators.required, Validators.min(1)]],
      isCovered: [false],
      vehicleTypes: [['Car'], Validators.required],
      sections: this.fb.array([])
    });
  }

  get vehicleTypesControl() {
    return this.levelForm.get('vehicleTypes');
  }

  toggleVehicleType(type: string) {
    const currentTypes = this.vehicleTypesControl?.value as string[] || [];
    if (currentTypes.includes(type)) {
      this.vehicleTypesControl?.setValue(currentTypes.filter(t => t !== type));
    } else {
      this.vehicleTypesControl?.setValue([...currentTypes, type]);
    }
  }

  isVehicleTypeSelected(type: string): boolean {
    return (this.vehicleTypesControl?.value as string[] || []).includes(type);
  }

  get sections() {
    return this.levelForm.get('sections') as FormArray;
  }

  addSection() {
    const section = this.fb.group({
      name: ['', Validators.required],
      totalCapacity: [10, [Validators.required, Validators.min(1)]],
      vehicleType: ['Car', Validators.required]
    });
    this.sections.push(section);
    this.updateTotalCapacity();
    
    // Listen to changes to update total capacity
    section.get('totalCapacity')?.valueChanges.subscribe(() => {
      this.updateTotalCapacity();
    });
  }

  removeSection(index: number) {
    this.sections.removeAt(index);
    this.updateTotalCapacity();
  }

  updateTotalCapacity() {
    if (this.sections.length > 0) {
      const total = this.sections.controls.reduce((acc, curr) => {
        return acc + (curr.get('totalCapacity')?.value || 0);
      }, 0);
      this.levelForm.patchValue({ totalCapacity: total });
    }
  }

  ngOnInit() {
    this.loadVenues();
  }

  loadVenues() {
    this.venuesService.getVenues().subscribe(venues => {
      this.venues = venues;
      
      // Check for query param to restore view state
      const venueIdParam = this.route.snapshot.queryParamMap.get('venueId');
      if (venueIdParam) {
        const venue = venues.find(v => v.id === venueIdParam);
        if (venue) {
          this.selectedProperty = venue.id;
          this.viewMode = 'details';
        }
      }

      if (venues.length > 0) {
        // If we have a selected property (e.g. after adding one), keep it selected
        if (!this.selectedProperty || !venues.find(v => v.id === this.selectedProperty)) {
          // Don't auto-select in list mode
          if (this.viewMode === 'details') {
             this.selectedProperty = venues[0].id;
          }
        }
        this.onVenueChange();
      }
    });
  }

  switchToDetails(venue: Venue) {
    this.selectedProperty = venue.id;
    this.onVenueChange();
    this.viewMode = 'details';
    
    // Track venue configuration view
    this.activityTracker.log({
      action: 'VIEW_VENUE_CONFIG',
      details: `Opened Venue Configuration for ${venue.name}`,
      venueId: venue.id,
      venueName: venue.name
    });
  }

  switchToList() {
    this.viewMode = 'list';
    this.selectedProperty = '';
    this.selectedVenue = null;
  }

  // Property Management
  selectedFile: File | null = null;

  openAddPropertyModal() {
    this.isEditingProperty = false;
    this.editingVenueId = null;
    this.propertyForm.reset({
      supportsRealTimeBooking: true,
      supportsFutureBooking: false,
      requireVehicleDetails: true,
      hasCoveredParking: false,
      hasCCTV: false
    });
    this.selectedFile = null;
    this.showAddPropertyModal = true;
  }

  openEditPropertyModal(venue: Venue) {
    this.isEditingProperty = true;
    this.editingVenueId = venue.id;
    this.propertyForm.patchValue({
      name: venue.name,
      address: venue.address,
      description: venue.description,
      imageUrl: venue.imageUrl,
      latitude: venue.latitude ?? 14.5995,
      longitude: venue.longitude ?? 120.9842,
      supportsRealTimeBooking: venue.supportsRealTimeBooking ?? true,
      supportsFutureBooking: venue.supportsFutureBooking ?? false,
      requireVehicleDetails: venue.requireVehicleDetails ?? true,
      hasCoveredParking: venue.hasCoveredParking ?? false,
      hasCCTV: venue.hasCCTV ?? false
    });
    this.selectedFile = null;
    this.showAddPropertyModal = true;
  }

  closeAddPropertyModal() {
    this.showAddPropertyModal = false;
  }

  onFileSelected(event: any) {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
    }
  }

  onSubmitProperty() {
    if (this.propertyForm.invalid) return;

    this.isSubmitting = true;

    // If editing and no file selected, we might want to send JSON instead of FormData?
    // Or just send FormData without file.
    // Backend handles partial updates?
    // The updateVenue in service takes Partial<Venue>.
    // But if we use FormData for update, we need to change service method signature or logic.
    // Let's check if update endpoint supports FormData.
    // The controller uses @Body() updateVenueDto: UpdateVenueDto. It does NOT use FileInterceptor for update.
    // So update does not support image upload currently?
    // Wait, I checked the controller earlier.
    // @Patch(':id') ... async update(@Body() updateVenueDto: UpdateVenueDto)
    // It does NOT have @UseInterceptors(FileInterceptor('image'...))
    // So image update is not supported in the current backend implementation for update.
    // I will proceed with JSON update for now, and FormData for create.

    if (this.isEditingProperty && this.editingVenueId) {
      // Use FormData for update as well to support image upload
      const formData = new FormData();
      Object.keys(this.propertyForm.value).forEach(key => {
        const value = this.propertyForm.value[key];
        if (value !== null && value !== undefined) {
          formData.append(key, value);
        }
      });

      if (this.selectedFile) {
        formData.append('image', this.selectedFile);
      }

      // We need to cast to any because updateVenue expects Partial<Venue> but we are sending FormData
      // The service needs to be updated to accept FormData for updateVenue as well
      // Or we can just cast it here if the HTTP client handles it correctly (Angular HttpClient does)
      this.venuesService.updateVenue(this.editingVenueId, formData).subscribe({
        next: (updatedVenue) => {
          this.isSubmitting = false;
          this.showAddPropertyModal = false;
          this.loadVenues();
        },
        error: (err) => {
          console.error('Failed to update venue', err);
          this.isSubmitting = false;
        }
      });
    } else {
      const formData = new FormData();
      Object.keys(this.propertyForm.value).forEach(key => {
        const value = this.propertyForm.value[key];
        if (value !== null && value !== undefined) {
          formData.append(key, value);
        }
      });

      if (this.selectedFile) {
        formData.append('image', this.selectedFile);
      }

      this.venuesService.createVenue(formData).subscribe({
        next: (newVenue) => {
          this.isSubmitting = false;
          this.showAddPropertyModal = false;
          if (this.viewMode === 'details') {
             this.selectedProperty = newVenue.id;
          }
          this.loadVenues();
        },
        error: (err) => {
          console.error('Failed to create venue', err);
          this.isSubmitting = false;
        }
      });
    }
  }

  deleteVenue(venue: Venue) {
    if (!confirm(`Are you sure you want to delete ${venue.name}? This will also delete all associated levels.`)) return;
    
    this.venuesService.deleteVenue(venue.id).subscribe({
      next: () => {
        this.loadVenues();
        if (this.selectedProperty === venue.id) {
          this.switchToList();
        }
      },
      error: (err) => {
        console.error('Failed to delete venue', err);
      }
    });
  }



  // Level Management
  openAddLevelModal() {
    this.levelForm.reset({
      levelNumber: (this.parkingLevels.length > 0 ? Math.max(...this.parkingLevels.map(l => l.levelNumber)) + 1 : 1),
      name: '',
      totalCapacity: 50
    });
    this.showAddLevelModal = true;
  }

  closeAddLevelModal() {
    this.showAddLevelModal = false;
  }

  onSubmitLevel() {
    if (this.levelForm.invalid || !this.selectedProperty) return;

    this.isSubmitting = true;
    this.venuesService.createLevel(this.selectedProperty, this.levelForm.value).subscribe({
      next: () => {
        this.isSubmitting = false;
        this.closeAddLevelModal();
        this.loadVenues(); // Reload to get updated levels
      },
      error: (err) => {
        console.error('Failed to create level', err);
        this.isSubmitting = false;
      }
    });
  }

  updateLevelCapacity(level: any) {
    if (!level.id) return;
    
    this.venuesService.updateLevel(level.id, { totalCapacity: level.capacity }).subscribe({
      next: () => {
        // Success toast could go here
        this.loadVenues();
      },
      error: (err) => {
        console.error('Failed to update capacity', err);
        // Revert change on error
        this.loadVenues();
      }
    });
  }

  toggleLevelStatus(level: any) {
    if (!level.id) return;

    this.venuesService.updateLevel(level.id, { isActive: level.isActive }).subscribe({
      next: () => {
        this.loadVenues();
      },
      error: (err) => {
        console.error('Failed to update status', err);
        level.isActive = !level.isActive; // Revert
      }
    });
  }

  deleteLevel(level: any) {
    if (!level.id || !confirm(`Are you sure you want to delete ${level.name}?`)) return;

    this.venuesService.deleteLevel(level.id).subscribe({
      next: () => {
        this.loadVenues();
      },
      error: (err) => {
        console.error('Failed to delete level', err);
      }
    });
  }

  onVenueChange() {
    this.selectedVenue = this.venues.find(v => v.id === this.selectedProperty) || null;
    if (this.selectedVenue) {
      this.parkingLevels = this.selectedVenue.levels
        .sort((a, b) => a.levelNumber - b.levelNumber)
        .map(level => ({
          id: level.id,
          levelNumber: level.levelNumber,
          name: level.name,
          zone: `Level ${level.levelNumber}`,
          type: level.isCovered ? 'Covered' : 'Open Air',
          typeIcon: level.isCovered ? 'roofing' : 'wb_sunny',
          vehicleTypes: level.vehicleTypes || ['Car'],
          capacity: level.totalCapacity,
          occupancy: level.totalCapacity - level.availableSpots,
          occupancyPercent: level.totalCapacity > 0 ? Math.round(((level.totalCapacity - level.availableSpots) / level.totalCapacity) * 100) : 0,
          status: level.isActive ? 'Open' : 'Closed',
          isActive: level.isActive
        }));
    } else {
      this.parkingLevels = [];
    }
  }

  get totalCapacity(): number {
    return this.parkingLevels.reduce((acc, level) => acc + level.capacity, 0);
  }

  get currentOccupancy(): number {
    return this.parkingLevels.reduce((acc, level) => acc + level.occupancy, 0);
  }

  get occupancyPercentage(): number {
    return this.totalCapacity > 0 ? Math.round((this.currentOccupancy / this.totalCapacity) * 100) : 0;
  }

  get activeLevelsCount(): number {
    return this.parkingLevels.filter(l => l.isActive).length;
  }
  
  get totalLevelsCount(): number {
    return this.parkingLevels.length;
  }
}
