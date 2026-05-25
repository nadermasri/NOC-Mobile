import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_noc/core/theme/app_theme.dart';
import 'package:pocket_noc/core/router/app_router.dart';
import 'package:pocket_noc/core/providers/app_providers.dart';
import 'package:pocket_noc/core/services/storage_service.dart';
import 'package:pocket_noc/core/services/api_service.dart';
import 'package:pocket_noc/core/services/auth_service.dart';
import 'package:pocket_noc/core/services/monitor_service.dart';
import 'package:pocket_noc/core/services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await StorageService().init();
  await AuthService().init();
  ApiService().init();
  MonitorService().init();
  AlertService().init();

  runApp(const ProviderScope(child: PocketNocApp()));
}

class PocketNocApp extends ConsumerWidget {
  const PocketNocApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Pocket NOC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
