import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { UsersComponent } from './users/users.component';
import { VenuesComponent } from './venues/venues.component';
import { ReservationsComponent } from './reservations/reservations.component';
import { LogsComponent } from './logs/logs.component';
import { FinanceComponent } from './finance/finance.component';
import { RatesComponent } from './venues/rates/rates.component';
import { ProfileComponent } from './profile/profile.component';
import { authGuard, guestGuard } from './core/guards/auth.guard';

export const routes: Routes = [
    { path: 'login', component: LoginComponent, canActivate: [guestGuard] },
    { path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] },
    { path: 'users', component: UsersComponent, canActivate: [authGuard] },
    { path: 'venues', component: VenuesComponent, canActivate: [authGuard] },
    { path: 'venues/rates', component: RatesComponent, canActivate: [authGuard] },
    { path: 'reservations', component: ReservationsComponent, canActivate: [authGuard] },
    { path: 'logs', component: LogsComponent, canActivate: [authGuard] },
    { path: 'finance', component: FinanceComponent, canActivate: [authGuard] },
    { path: 'profile', component: ProfileComponent, canActivate: [authGuard] },
    { path: '', redirectTo: 'login', pathMatch: 'full' }
];
