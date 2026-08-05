import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vetmate/features/auth/models/auth_state.dart';
import 'package:vetmate/features/auth/providers/auth_provider.dart';
import 'package:vetmate/features/auth/screens/role_selection_screen.dart';
import 'package:vetmate/features/auth/screens/auth_screen.dart';
import 'package:vetmate/features/auth/screens/splash_screen.dart';
import 'package:vetmate/features/home/screens/home_screen.dart';
import 'package:vetmate/features/home/screens/book_slot_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Refresh listener forces GoRouter to re-evaluate redirects when auth status changes
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final status = auth.status;

      // Allow splash to render without interference
      if (state.matchedLocation == '/') {
        return null;
      }

      // Wait if status is loading or initial
      if (status == AuthStatus.loading || status == AuthStatus.initial) {
        return null;
      }

      final isAuthenticated = status == AuthStatus.authenticated;
      final isEnteringAuth =
          state.matchedLocation == '/auth' || state.matchedLocation == '/role';

      if (!isAuthenticated && !isEnteringAuth) {
        // Protected route accessed without auth -> Redirect to Role selection page
        return '/role';
      }

      if (isAuthenticated && isEnteringAuth) {
        // Authenticated user trying to access Auth screens -> Redirect to Home dashboard
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/book-slot/:clinicId',
        builder: (context, state) {
          final clinicId = state.pathParameters['clinicId']!;
          return BookSlotScreen(clinicId: clinicId);
        },
      ),
    ],
  );
});

// Helper class to map Stream into Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
