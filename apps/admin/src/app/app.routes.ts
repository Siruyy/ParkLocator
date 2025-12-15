import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { VenuesComponent } from './venues/venues.component';

export const routes: Routes = [
    { path: 'login', component: LoginComponent },
    { path: 'dashboard', component: DashboardComponent },
    { path: 'venues', component: VenuesComponent },
    { path: '', redirectTo: 'login', pathMatch: 'full' }
];
