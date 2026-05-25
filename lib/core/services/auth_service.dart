import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  late final Box<dynamic> _box;
  late final Dio _dio;

  Future<void> init() async {
    _box = await Hive.openBox('auth');
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}/api/auth',
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
  }

  bool get isLoggedIn => _box.get(_accessTokenKey) != null;
  String? get accessToken => _box.get(_accessTokenKey) as String?;
  String? get refreshToken => _box.get(_refreshTokenKey) as String?;

  Map<String, dynamic>? get currentUser {
    final data = _box.get(_userKey);
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  String get userPlan => currentUser?['plan'] ?? 'free';

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String displayName = '',
  }) async {
    try {
      final response = await _dio.post('/signup', data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      });
      await _saveTokens(response.data);
      return {'success': true, 'user': response.data['user']};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      await _saveTokens(response.data);
      return {'success': true, 'user': response.data['user']};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<bool> refreshAccessToken() async {
    final token = refreshToken;
    if (token == null) return false;
    try {
      final response = await _dio.post('/refresh', queryParameters: {
        'token': token,
      });
      await _saveTokens(response.data);
      return true;
    } on DioException {
      await logout();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/me',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
      final user = Map<String, dynamic>.from(response.data as Map);
      await _box.put(_userKey, user);
      return user;
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    await _box.delete(_accessTokenKey);
    await _box.delete(_refreshTokenKey);
    await _box.delete(_userKey);
  }

  Future<bool> deleteAccount() async {
    try {
      await _dio.delete('/me',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}));
      await logout();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _box.put(_accessTokenKey, data['access_token']);
    await _box.put(_refreshTokenKey, data['refresh_token']);
    if (data['user'] != null) {
      await _box.put(_userKey, Map<String, dynamic>.from(data['user'] as Map));
    }
  }

  Map<String, dynamic> _handleError(DioException e) {
    final detail = e.response?.data is Map
        ? (e.response!.data as Map)['detail'] ?? 'Request failed'
        : e.message ?? 'Request failed';
    return {'success': false, 'error': detail.toString()};
  }
}
