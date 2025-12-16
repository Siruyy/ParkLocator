import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { CheckboxModule } from 'primeng/checkbox';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { AuthService } from '../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, CheckboxModule, ButtonModule, InputTextModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  email = '';
  password = '';
  rememberMe = false;
  passwordVisible = false;
  validationError = '';

  private returnUrl = '/dashboard';

  constructor(
    private router: Router,
    private route: ActivatedRoute,
    public authService: AuthService
  ) {
    // Get return URL from route parameters or default to dashboard
    this.returnUrl = this.route.snapshot.queryParams['returnUrl'] || '/dashboard';
  }

  onLogin() {
    this.validationError = '';
    
    if (!this.email || !this.password) {
      this.validationError = 'Please enter both email and password.';
      return;
    }

    this.authService.login({ email: this.email, password: this.password }).subscribe({
      next: () => {
        this.router.navigate([this.returnUrl]);
      },
      error: (err) => {
        console.error('Login failed:', err);
      }
    });
  }
}
