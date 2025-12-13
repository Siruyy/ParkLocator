import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/api/api.dart';
import 'package:mobile/auth/bloc/auth_bloc.dart';
import 'package:mobile/auth/repository/src/auth_repository.dart';
import 'package:mobile/common/common.dart';
import 'package:mobile/home/home.dart';
import 'package:mobile/l10n/l10n.dart';
import 'package:mobile/login/login.dart';
import 'package:mobile/venues/repository/venues_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final VenuesRepository _venuesRepository;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepository = AuthRepository(apiClient: _apiClient);
    _venuesRepository = VenuesRepository(apiClient: _apiClient);
    _authBloc = AuthBloc(authRepository: _authRepository)
      ..add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    _authRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _venuesRepository),
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
                return const HomePage();
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
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.local_parking,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ParkLocator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
