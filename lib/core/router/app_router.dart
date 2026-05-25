import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/features/onboarding/onboarding_screen.dart';
import 'package:pocket_noc/features/dashboard/dashboard_screen.dart';
import 'package:pocket_noc/features/targets/targets_screen.dart';
import 'package:pocket_noc/features/targets/target_form_screen.dart';
import 'package:pocket_noc/features/ping/ping_screen.dart';
import 'package:pocket_noc/features/traceroute/traceroute_screen.dart';
import 'package:pocket_noc/features/dns/dns_screen.dart';
import 'package:pocket_noc/features/reverse_dns/reverse_dns_screen.dart';
import 'package:pocket_noc/features/port_check/port_check_screen.dart';
import 'package:pocket_noc/features/http_headers/http_headers_screen.dart';
import 'package:pocket_noc/features/tls_check/tls_check_screen.dart';
import 'package:pocket_noc/features/subnet_calc/subnet_calc_screen.dart';
import 'package:pocket_noc/features/report/report_screen.dart';
import 'package:pocket_noc/features/ai_explain/ai_explain_screen.dart';
import 'package:pocket_noc/features/settings/settings_screen.dart';
import 'package:pocket_noc/features/settings/privacy_policy_screen.dart';
import 'package:pocket_noc/features/auth/login_screen.dart';
import 'package:pocket_noc/features/auth/signup_screen.dart';
import 'package:pocket_noc/features/auth/profile_screen.dart';
import 'package:pocket_noc/features/monitoring/monitors_screen.dart';
import 'package:pocket_noc/features/monitoring/create_monitor_screen.dart';
import 'package:pocket_noc/features/monitoring/monitor_detail_screen.dart';
import 'package:pocket_noc/features/alerts/alerts_screen.dart';
import 'package:pocket_noc/features/upgrade/upgrade_screen.dart';
import 'package:pocket_noc/core/widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: onboardingComplete ? '/dashboard' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/monitors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MonitorsScreen(),
            ),
          ),
          GoRoute(
            path: '/alerts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AlertsScreen(),
            ),
          ),
          GoRoute(
            path: '/targets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TargetsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradeScreen(),
      ),
      // Monitor routes
      GoRoute(
        path: '/monitors/create',
        builder: (context, state) => const CreateMonitorScreen(),
      ),
      GoRoute(
        path: '/monitors/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return MonitorDetailScreen(monitorId: id);
        },
      ),
      // Target routes
      GoRoute(
        path: '/targets/add',
        builder: (context, state) => const TargetFormScreen(),
      ),
      GoRoute(
        path: '/targets/edit/:id',
        builder: (context, state) => TargetFormScreen(
          targetId: state.pathParameters['id'],
        ),
      ),
      // Tool routes
      GoRoute(
        path: '/tools/ping',
        builder: (context, state) => PingScreen(
          initialHost: state.uri.queryParameters['host'],
        ),
      ),
      GoRoute(
        path: '/tools/traceroute',
        builder: (context, state) => TracerouteScreen(
          initialHost: state.uri.queryParameters['host'],
        ),
      ),
      GoRoute(
        path: '/tools/dns',
        builder: (context, state) => DnsScreen(
          initialDomain: state.uri.queryParameters['domain'],
        ),
      ),
      GoRoute(
        path: '/tools/reverse-dns',
        builder: (context, state) => ReverseDnsScreen(
          initialIp: state.uri.queryParameters['ip'],
        ),
      ),
      GoRoute(
        path: '/tools/port-check',
        builder: (context, state) => PortCheckScreen(
          initialHost: state.uri.queryParameters['host'],
        ),
      ),
      GoRoute(
        path: '/tools/http-headers',
        builder: (context, state) => HttpHeadersScreen(
          initialUrl: state.uri.queryParameters['url'],
        ),
      ),
      GoRoute(
        path: '/tools/tls-check',
        builder: (context, state) => TlsCheckScreen(
          initialDomain: state.uri.queryParameters['domain'],
        ),
      ),
      GoRoute(
        path: '/tools/subnet-calc',
        builder: (context, state) => const SubnetCalcScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => ReportScreen(
          targetHost: state.uri.queryParameters['host'],
        ),
      ),
      GoRoute(
        path: '/ai-explain',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AiExplainScreen(diagnosticData: extra ?? {});
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
});
