import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/models/target.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Target> _targetsBox;
  late Box<DiagnosticResult> _resultsBox;
  late Box<dynamic> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TargetAdapter());
    Hive.registerAdapter(DiagnosticResultAdapter());

    _targetsBox = await Hive.openBox<Target>(AppConstants.targetsBoxName);
    _resultsBox =
        await Hive.openBox<DiagnosticResult>(AppConstants.resultsBoxName);
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  }

  // Settings
  T? getSetting<T>(String key) => _settingsBox.get(key) as T?;

  Future<void> setSetting<T>(String key, T value) =>
      _settingsBox.put(key, value);

  bool get onboardingComplete =>
      _settingsBox.get(AppConstants.onboardingCompleteKey, defaultValue: false)
          as bool;

  Future<void> setOnboardingComplete() =>
      _settingsBox.put(AppConstants.onboardingCompleteKey, true);

  bool get isDarkMode =>
      _settingsBox.get(AppConstants.darkModeKey, defaultValue: true) as bool;

  Future<void> setDarkMode(bool value) =>
      _settingsBox.put(AppConstants.darkModeKey, value);

  // Targets
  List<Target> getAllTargets() => _targetsBox.values.toList();

  Target? getTarget(String id) => _targetsBox.get(id);

  Future<void> saveTarget(Target target) => _targetsBox.put(target.id, target);

  Future<void> deleteTarget(String id) => _targetsBox.delete(id);

  // Results
  List<DiagnosticResult> getAllResults() {
    final results = _resultsBox.values.toList();
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  List<DiagnosticResult> getResultsByType(String type) {
    return _resultsBox.values
        .where((r) => r.type == type)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<DiagnosticResult> getResultsByTarget(String target) {
    return _resultsBox.values
        .where((r) => r.target == target)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  DiagnosticResult? getLastResult() {
    if (_resultsBox.isEmpty) return null;
    final results = getAllResults();
    return results.first;
  }

  Future<void> saveResult(DiagnosticResult result) =>
      _resultsBox.put(result.id, result);

  Future<void> deleteResult(String id) => _resultsBox.delete(id);

  Future<void> clearResults() => _resultsBox.clear();

  Future<void> clearAll() async {
    await _targetsBox.clear();
    await _resultsBox.clear();
  }

  Map<String, dynamic> exportData() {
    return {
      'targets': getAllTargets().map((t) => t.toJson()).toList(),
      'results': getAllResults().map((r) => r.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
