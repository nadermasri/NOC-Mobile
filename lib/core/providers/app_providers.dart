import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_noc/core/services/storage_service.dart';
import 'package:pocket_noc/core/services/network_diagnostics_service.dart';
import 'package:pocket_noc/core/services/api_service.dart';
import 'package:pocket_noc/core/services/auth_service.dart';
import 'package:pocket_noc/core/services/monitor_service.dart';
import 'package:pocket_noc/core/services/alert_service.dart';
import 'package:pocket_noc/core/models/target.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';

// Services
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final networkDiagnosticsProvider = Provider<NetworkDiagnosticsService>((ref) {
  return NetworkDiagnosticsService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final monitorServiceProvider = Provider<MonitorService>((ref) {
  return MonitorService();
});

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService();
});

// Auth state
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final auth = ref.read(authServiceProvider);
  return AuthStateNotifier(auth);
});

class AuthState {
  final bool isLoggedIn;
  final Map<String, dynamic>? user;
  final bool isLoading;

  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({bool? isLoggedIn, Map<String, dynamic>? user, bool? isLoading}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String get plan => user?['plan'] ?? 'free';
  String get displayName => user?['display_name'] ?? '';
  String get email => user?['email'] ?? '';
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;

  AuthStateNotifier(this._auth)
      : super(AuthState(
          isLoggedIn: _auth.isLoggedIn,
          user: _auth.currentUser,
        ));

  Future<Map<String, dynamic>> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _auth.login(email: email, password: password);
    if (result['success'] == true) {
      state = AuthState(
        isLoggedIn: true,
        user: Map<String, dynamic>.from(result['user'] as Map),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }

  Future<Map<String, dynamic>> signup(
      String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true);
    final result = await _auth.signup(
        email: email, password: password, displayName: displayName);
    if (result['success'] == true) {
      state = AuthState(
        isLoggedIn: true,
        user: Map<String, dynamic>.from(result['user'] as Map),
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AuthState();
  }

  Future<void> refreshProfile() async {
    final user = await _auth.getProfile();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }
}

// Monitors
final monitorsProvider =
    StateNotifierProvider<MonitorsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final service = ref.read(monitorServiceProvider);
  return MonitorsNotifier(service);
});

class MonitorsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final MonitorService _service;

  MonitorsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    final monitors = await _service.listMonitors();
    state = AsyncValue.data(monitors);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final result = await _service.createMonitor(data);
    if (result['success'] == true) await load();
    return result;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final result = await _service.updateMonitor(id, data);
    if (result['success'] == true) await load();
    return result;
  }

  Future<bool> delete(int id) async {
    final ok = await _service.deleteMonitor(id);
    if (ok) await load();
    return ok;
  }

  Future<Map<String, dynamic>?> runCheck(int id) async {
    final result = await _service.runCheck(id);
    await load();
    return result;
  }
}

// Alerts
final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final service = ref.read(alertServiceProvider);
  return AlertsNotifier(service);
});

final unreadAlertCountProvider = StateProvider<int>((ref) => 0);

class AlertsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AlertService _service;

  AlertsNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> load({String? status, String? severity}) async {
    state = const AsyncValue.loading();
    final alerts =
        await _service.listAlerts(status: status, severity: severity);
    state = AsyncValue.data(alerts);
  }

  Future<bool> acknowledge(int id) async {
    final ok = await _service.acknowledgeAlert(id);
    if (ok) await load();
    return ok;
  }

  Future<bool> resolve(int id) async {
    final ok = await _service.resolveAlert(id);
    if (ok) await load();
    return ok;
  }

  Future<int> acknowledgeAll() async {
    final count = await _service.acknowledgeAll();
    await load();
    return count;
  }
}

// Theme
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.read(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage)
      : super(_storage.isDarkMode ? ThemeMode.dark : ThemeMode.light);

  void toggle() {
    final isDark = state == ThemeMode.dark;
    _storage.setDarkMode(!isDark);
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  void setDarkMode(bool dark) {
    _storage.setDarkMode(dark);
    state = dark ? ThemeMode.dark : ThemeMode.light;
  }
}

// Onboarding
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  final storage = ref.read(storageServiceProvider);
  return storage.onboardingComplete;
});

// Targets
final targetsProvider =
    StateNotifierProvider<TargetsNotifier, List<Target>>((ref) {
  final storage = ref.read(storageServiceProvider);
  return TargetsNotifier(storage);
});

class TargetsNotifier extends StateNotifier<List<Target>> {
  final StorageService _storage;

  TargetsNotifier(this._storage) : super(_storage.getAllTargets());

  void refresh() {
    state = _storage.getAllTargets();
  }

  Future<void> add(Target target) async {
    await _storage.saveTarget(target);
    state = _storage.getAllTargets();
  }

  Future<void> update(Target target) async {
    await _storage.saveTarget(target);
    state = _storage.getAllTargets();
  }

  Future<void> delete(String id) async {
    await _storage.deleteTarget(id);
    state = _storage.getAllTargets();
  }
}

// Diagnostic Results
final resultsProvider =
    StateNotifierProvider<ResultsNotifier, List<DiagnosticResult>>((ref) {
  final storage = ref.read(storageServiceProvider);
  return ResultsNotifier(storage);
});

class ResultsNotifier extends StateNotifier<List<DiagnosticResult>> {
  final StorageService _storage;

  ResultsNotifier(this._storage) : super(_storage.getAllResults());

  void refresh() {
    state = _storage.getAllResults();
  }

  Future<void> add(DiagnosticResult result) async {
    await _storage.saveResult(result);
    state = _storage.getAllResults();
  }

  Future<void> delete(String id) async {
    await _storage.deleteResult(id);
    state = _storage.getAllResults();
  }

  Future<void> clearAll() async {
    await _storage.clearResults();
    state = [];
  }
}

// Public IP
final publicIpProvider = FutureProvider<String?>((ref) async {
  final diagnostics = ref.read(networkDiagnosticsProvider);
  return diagnostics.getPublicIp();
});

// Loading state for tools
final toolLoadingProvider = StateProvider<bool>((ref) => false);
