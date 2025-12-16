import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from '../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../layout/header/header.component';

@Component({
  selector: 'app-venues',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule, SidebarComponent, HeaderComponent],
  templateUrl: './venues.component.html',
  styleUrl: './venues.component.scss'
})
export class VenuesComponent {
  selectedProperty = 'ayala';
  
  parkingLevels = [
    {
      id: 'L1',
      name: 'Level 1 - Main',
      zone: 'Near Entrance A',
      type: 'Car',
      typeIcon: 'directions_car',
      capacity: 120,
      occupancy: 108,
      occupancyPercent: 90,
      status: 'Open',
      isActive: true
    },
    {
      id: 'B1',
      name: 'Basement 1',
      zone: 'VIP & Valet',
      type: 'Car',
      typeIcon: 'directions_car',
      capacity: 50,
      occupancy: 45,
      occupancyPercent: 90,
      status: 'Open',
      isActive: true
    },
    {
      id: 'B2',
      name: 'Basement 2',
      zone: 'Maintenance Zone',
      type: 'Moto',
      typeIcon: 'two_wheeler',
      capacity: 200,
      occupancy: 0,
      occupancyPercent: 0,
      status: 'Closed',
      isActive: false
    },
    {
      id: 'L2',
      name: 'Level 2',
      zone: 'Cinema Parking',
      type: 'Car',
      typeIcon: 'directions_car',
      capacity: 180,
      occupancy: 98,
      occupancyPercent: 54,
      status: 'Open',
      isActive: true
    }
  ];
}
