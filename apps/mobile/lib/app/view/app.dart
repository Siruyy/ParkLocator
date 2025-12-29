import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/app/view/main_navigation_page.dart';
import 'package:mobile/attendant/view/attendant_home_page.dart';
import 'package:mobile/auth/bloc/auth_bloc.dart';
import 'package:mobile/auth/repository/src/auth_repository.dart';
import 'package:mobile/common/common.dart';
import 'package:mobile/l10n/l10n.dart';
import 'package:mobile/login/login.dart';
import 'package:mobile/reservations/repository/reservations_repository.dart';
import 'package:mobile/venues/repository/venues_repository.dart';
import 'package:mobile/profile/repository/vehicles_repository.dart';
import 'package:mobile/notifications/repository/notifications_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ApiClient _apiClient;
  late final RealtimeService _realtimeService;
  late final AuthRepository _authRepository;
  late final VenuesRepository _venuesRepository;
  late final ReservationsRepository _reservationsRepository;
  late final VehiclesRepository _vehiclesRepository;
  late final NotificationsRepository _notificationsRepository;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _realtimeService = RealtimeService();
    _authRepository = AuthRepository(apiClient: _apiClient);
    _venuesRepository = VenuesRepository(apiClient: _apiClient);
    _reservationsRepository = ReservationsRepository(apiClient: _apiClient);
    _vehiclesRepository = VehiclesRepository(apiClient: _apiClient);
    _notificationsRepository = NotificationsRepository(apiClient: _apiClient);
    _authBloc = AuthBloc(authRepository: _authRepository)
      ..add(const AuthCheckRequested());
      
    _realtimeService.connect();
  }

  @override
  void dispose() {
    _authBloc.close();
    _authRepository.dispose();
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _apiClient),
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _venuesRepository),
        RepositoryProvider.value(value: _reservationsRepository),
        RepositoryProvider.value(value: _vehiclesRepository),
        RepositoryProvider.value(value: _notificationsRepository),
        RepositoryProvider.value(value: _realtimeService),
      ],
      child: BlocProvider.value(
        value: _authBloc,
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Auth state changes are handled by the builder
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            switch (state.status) {
              case AuthStatus.unknown:
                return const _SplashScreen();
              case AuthStatus.authenticated:
                final user = state.user;
                if (user?.role == 'ATTENDANT') {
                  return const AttendantHomePage();
                }
                return const MainNavigationPage();
              case AuthStatus.unauthenticated:
                return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/parking_boy.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 24),
            const Text(
              'ParkLocator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
