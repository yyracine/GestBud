import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/settings_screen.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/dashboard/screens/home_shell.dart';
import '../../features/scan/screens/scan_entry_screen.dart';
import '../../features/transactions/screens/history_screen.dart';
import '../domain/session_state.dart';
import '../providers/session_provider.dart';

const _kAuthPhone = '/auth/phone';
const _kHome = '/home';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);
  return GoRouter(
    initialLocation: _kAuthPhone,
    refreshListenable: router,
    redirect: router._redirect,
    routes: [
      GoRoute(
        path: _kAuthPhone,
        builder: (_, _) => const AuthPhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/scan/entry',
        builder: (_, _) => const ScanEntryScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: _kHome,
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const _DashboardPlaceholder(),
          ),
        ],
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<SessionState>>(sessionStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;

  String? _redirect(BuildContext context, GoRouterState state) {
    final session = _ref.read(sessionStateProvider);
    final isAuth = state.matchedLocation.startsWith('/auth');

    return session.when(
      data: (s) {
        if (s is SessionAuthenticated && isAuth) return _kHome;
        if (s is SessionUnauthenticated && !isAuth) return _kAuthPhone;
        return null;
      },
      loading: () => null,
      error: (_, _) => _kAuthPhone,
    );
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
