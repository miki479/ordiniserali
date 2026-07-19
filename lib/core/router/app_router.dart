import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/session_controller.dart';
import '../../presentation/providers/session_state.dart';
import '../../presentation/screens/auth/auth_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/welcome_back/welcome_back_screen.dart';
import 'route_names.dart';

/// Bridges Riverpod state changes into GoRouter's `refreshListenable`, so a
/// [SessionState] transition re-evaluates `redirect` without recreating the
/// router (which would otherwise reset navigation state).
class _SessionRefreshNotifier extends ChangeNotifier {
  _SessionRefreshNotifier(Ref ref) {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      final target = switch (session) {
        SessionUnknown() => AppRoutes.splash,
        SessionLoggedOut() => AppRoutes.auth,
        SessionNeedsWelcomeBack() => AppRoutes.welcomeBack,
        SessionActive() => AppRoutes.home,
      };
      return location == target ? null : target;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcomeBack,
        builder: (context, state) => const WelcomeBackScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
