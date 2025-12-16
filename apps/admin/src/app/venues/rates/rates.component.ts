import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SidebarComponent } from '../../layout/sidebar/sidebar.component';
import { HeaderComponent } from '../../layout/header/header.component';

@Component({
  selector: 'app-rates',
  standalone: true,
  imports: [CommonModule, RouterModule, SidebarComponent, HeaderComponent],
  templateUrl: './rates.component.html',
  styleUrl: './rates.component.scss'
})
export class RatesComponent {}
