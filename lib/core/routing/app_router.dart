import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/mock_repository.dart';
import '../../features/accounts/accounts_page.dart';
import '../../features/authentication/login_page.dart';
import '../../features/overview/overview_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/renewals/renewals_page.dart';
import '../../features/vendor_applications/vendor_applications_page.dart';
import '../widgets/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  final router = GoRouter(
    initialLocation: ref.read(authProvider) ? '/overview' : '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(authProvider);
      final isLogin = state.matchedLocation == '/login';
      if (!signedIn && !isLogin) return '/login';
      if (signedIn && isLogin) return '/overview';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            builder: (context, state) => const OverviewPage(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsPage(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const VendorApplicationsPage(),
          ),
          GoRoute(
            path: '/renewal',
            builder: (context, state) => const RenewalsPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<bool>(authProvider, (previous, next) => notifyListeners());
  }
}
