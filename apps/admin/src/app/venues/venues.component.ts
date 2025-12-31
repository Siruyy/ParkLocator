import { Component, OnInit, inject, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';
import { VenuesService, Venue, Spot } from '../core/services/venues.service';
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
  isEditingLevel = false;
  editingLevelId: string | null = null;
  levelForm: FormGroup;
  isSubmitting = false;
  isSubmittingLevel = false;

  // Spot Management - Properties moved to method section for grouping


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

  addSection(data?: any) {
    const section = this.fb.group({
      name: [data?.name || '', Validators.required],
      totalCapacity: [data?.totalCapacity || 10, [Validators.required, Validators.min(1)]],
      vehicleType: [data?.vehicleType || 'Car', Validators.required]
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
    if (this.propertyForm.dirty) {
      if (!confirm('You have unsaved changes. Are you sure you want to close?')) {
        return;
      }
    }
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

    if (this.isEditingProperty && this.editingVenueId) {
      // If a file is selected, use FormData; otherwise use JSON to preserve boolean types
      if (this.selectedFile) {
        const formData = new FormData();
        
        Object.keys(this.propertyForm.value).forEach(key => {
          // Skip imageUrl - it should only be set by the backend when a new file is uploaded
          if (key === 'imageUrl') return;
          
          const value = this.propertyForm.value[key];
          if (value !== null && value !== undefined) {
            formData.append(key, String(value));
          }
        });

        formData.append('image', this.selectedFile);

        this.venuesService.updateVenue(this.editingVenueId, formData).subscribe({
          next: () => {
            this.isSubmitting = false;
            this.showAddPropertyModal = false;
            this.propertyForm.markAsPristine();
            this.loadVenues();
          },
          error: (err) => {
            console.error('Failed to update venue', err);
            this.isSubmitting = false;
          }
        });
      } else {
        // No file - send JSON to preserve boolean types
        const updateData: any = {};
        Object.keys(this.propertyForm.value).forEach(key => {
          // Skip imageUrl when no new file is selected
          if (key === 'imageUrl') return;
          
          const value = this.propertyForm.value[key];
          if (value !== null && value !== undefined) {
            updateData[key] = value;
          }
        });

        this.venuesService.updateVenueJson(this.editingVenueId, updateData).subscribe({
          next: () => {
            this.isSubmitting = false;
            this.showAddPropertyModal = false;
            this.propertyForm.markAsPristine();
            this.loadVenues();
          },
          error: (err) => {
            console.error('Failed to update venue', err);
            this.isSubmitting = false;
          }
        });
      }
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
    this.isEditingLevel = false;
    this.editingLevelId = null;
    this.levelForm.reset({
      levelNumber: (this.parkingLevels.length > 0 ? Math.max(...this.parkingLevels.map(l => l.levelNumber)) + 1 : 1),
      name: '',
      totalCapacity: 50,
      isCovered: false,
      vehicleTypes: ['Car']
    });
    this.sections.clear();
    this.showAddLevelModal = true;
  }

  openEditLevelModal(level: any) {
    this.isEditingLevel = true;
    this.editingLevelId = level.id;
    
    this.levelForm.patchValue({
      levelNumber: level.levelNumber,
      name: level.name,
      totalCapacity: level.capacity,
      isCovered: level.type === 'Covered',
      vehicleTypes: level.vehicleTypes || ['Car']
    });
    
    this.sections.clear();
    
    // Fetch spots to populate sections
    this.venuesService.getSpots(level.id).subscribe(spots => {
      const groups: { [key: string]: { count: number, vehicleType: string } } = {};
      
      spots.forEach(spot => {
        const sectionName = spot.section || 'General';
        if (!groups[sectionName]) {
          groups[sectionName] = { count: 0, vehicleType: spot.vehicleType };
        }
        groups[sectionName].count++;
      });

      Object.keys(groups).sort().forEach(name => {
        this.addSection({
          name: name,
          totalCapacity: groups[name].count,
          vehicleType: groups[name].vehicleType
        });
      });
      
      // If no sections found (legacy data), add a default one
      if (this.sections.length === 0 && level.capacity > 0) {
        this.addSection({
          name: 'General',
          totalCapacity: level.capacity,
          vehicleType: level.vehicleTypes?.[0] || 'Car'
        });
      }
    });

    this.showAddLevelModal = true;
  }

  closeAddLevelModal() {
    this.showAddLevelModal = false;
    this.isEditingLevel = false;
    this.editingLevelId = null;
  }

  onSubmitLevel() {
    if (this.levelForm.invalid || !this.selectedProperty) return;

    this.isSubmittingLevel = true;

    if (this.isEditingLevel && this.editingLevelId) {
      const updateDto = {
        name: this.levelForm.value.name,
        isCovered: this.levelForm.value.isCovered,
        vehicleTypes: this.levelForm.value.vehicleTypes,
        sections: this.sections.value,
        totalCapacity: this.levelForm.value.totalCapacity // Send total capacity as well, though backend recalculates
      };

      this.venuesService.updateLevel(this.editingLevelId, updateDto).subscribe({
        next: () => {
          this.isSubmittingLevel = false;
          this.closeAddLevelModal();
          this.loadVenues();
        },
        error: (err) => {
          console.error('Failed to update level', err);
          this.isSubmittingLevel = false;
          alert(err.error?.message || 'Failed to update level. Ensure you are not deleting occupied spots.');
        }
      });
    } else {
      const levelData = {
        ...this.levelForm.value,
        sections: this.sections.value
      };

      this.venuesService.createLevel(this.selectedProperty, levelData).subscribe({
        next: () => {
          this.isSubmittingLevel = false;
          this.closeAddLevelModal();
          this.loadVenues();
        },
        error: (err) => {
          console.error('Failed to create level', err);
          this.isSubmittingLevel = false;
        }
      });
    }
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

  // Spot Management
  spots: Spot[] = [];
  groupedSpots: { section: string, spots: Spot[] }[] = [];
  searchTerm: string = '';
  selectedLevelId: string | null = null;
  showManageSpotsModal = false;
  isLoadingSpots = false;

  openManageSpotsModal(level: any) {
    this.selectedLevelId = level.id;
    this.showManageSpotsModal = true;
    this.searchTerm = '';
    this.loadSpots(level.id);
  }

  loadSpots(levelId: string) {
    this.isLoadingSpots = true;
    this.venuesService.getSpots(levelId).subscribe({
      next: (spots) => {
        this.spots = spots.sort((a, b) => a.spotNumber.localeCompare(b.spotNumber, undefined, { numeric: true }));
        this.filterSpots();
        this.isLoadingSpots = false;
      },
      error: (err) => {
        console.error('Failed to load spots', err);
        this.isLoadingSpots = false;
      }
    });
  }

  filterSpots() {
    let filtered = this.spots;
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = this.spots.filter(s => 
        s.spotNumber.toLowerCase().includes(term) || 
        (s.section && s.section.toLowerCase().includes(term))
      );
    }
    
    // Group by section
    const groups: { [key: string]: Spot[] } = {};
    filtered.forEach(spot => {
      const section = spot.section || 'General';
      if (!groups[section]) {
        groups[section] = [];
      }
      groups[section].push(spot);
    });
    
    this.groupedSpots = Object.keys(groups).sort().map(section => ({
      section,
      spots: groups[section]
    }));
  }

  closeManageSpotsModal() {
    this.showManageSpotsModal = false;
    this.spots = [];
    this.groupedSpots = [];
    this.selectedLevelId = null;
    this.searchTerm = '';
    this.loadVenues();
  }

  toggleSpotMaintenance(spot: Spot) {
    const newStatus = spot.status === 'maintenance' ? 'available' : 'maintenance';
    
    // Optimistic update
    const oldStatus = spot.status;
    spot.status = newStatus;
    
    this.venuesService.updateSpotStatus(spot.id, newStatus).subscribe({
      error: (err) => {
        console.error('Failed to update spot status', err);
        spot.status = oldStatus; // Revert
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
