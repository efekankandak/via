import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/cubit/auth_cubit.dart';
import '../../features/auth/cubit/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/trip_planner/cubit/trip_planner_cubit.dart';
import '../../features/trip_planner/screens/trip_planner_screen.dart';
import '../../features/trip_detail/cubit/trip_detail_cubit.dart';
import '../../features/trip_detail/screens/generating_screen.dart';
import '../../features/trip_detail/screens/trip_detail_screen.dart';
import '../../features/place_detail/screens/place_detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../di/injection.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final authState = context.read<AuthCubit>().state;
        final hasUser = FirebaseAuth.instance.currentUser != null;
        final isAuthenticated = authState is AuthAuthenticated || hasUser;
        
        final isOnSplash = state.matchedLocation == '/splash';
        final isOnAuth = state.matchedLocation == '/login';

        // Splash ekranındayken otomatik yönlendirmeyi devre dışı bırakıyoruz.
        // Yönlendirme kararını splash ekranı kendi animasyonu bittikten sonra verecektir.
        if (isOnSplash) return null;

        if (!isAuthenticated && !isOnAuth) return '/login';
        if (isAuthenticated && isOnAuth) return '/home';
        return null;
      },
      refreshListenable: _AuthChangeNotifier(
        context.read<AuthCubit>(),
      ),
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/planner',
          name: 'planner',
          builder: (context, state) => BlocProvider(
            create: (_) => TripPlannerCubit(
              tripRepository: getIt<TripRepository>(),
              auth: FirebaseAuth.instance,
            ),
            child: const TripPlannerScreen(),
          ),
        ),
        GoRoute(
          path: '/generating/:tripId',
          name: 'generating',
          builder: (context, state) {
            final tripId = state.pathParameters['tripId']!;
            return BlocProvider(
              create: (_) => TripDetailCubit(
                tripRepository: getIt<TripRepository>(),
              ),
              child: GeneratingScreen(tripId: tripId),
            );
          },
        ),
        GoRoute(
          path: '/trip/:tripId',
          name: 'tripDetail',
          builder: (context, state) {
            final tripId = state.pathParameters['tripId']!;
            return BlocProvider(
              create: (_) => TripDetailCubit(
                tripRepository: getIt<TripRepository>(),
              ),
              child: TripDetailScreen(tripId: tripId),
            );
          },
        ),
        GoRoute(
          path: '/place',
          name: 'placeDetail',
          builder: (context, state) {
            final place = state.extra as PlaceEntity;
            return PlaceDetailScreen(place: place);
          },
        ),
        GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ChatScreen(
              tripId: extra['tripId'] as String?,
              placeName: extra['placeName'] as String?,
              city: extra['city'] as String?,
              tripTheme: extra['tripTheme'] as String?,
              initialMessage: extra['initialMessage'] as String?,
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFF85149), size: 48),
              const SizedBox(height: 16),
              Text(
                'Sayfa bulunamadı',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auth state değiştiğinde GoRouter'ı yeniler
class _AuthChangeNotifier extends ChangeNotifier {
  final AuthCubit _authCubit;

  _AuthChangeNotifier(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }
}
