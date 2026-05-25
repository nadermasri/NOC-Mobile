import 'package:dio/dio.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/services/auth_service.dart';

class MonitorService {
  static final MonitorService _instance = MonitorService._internal();
  factory MonitorService() => _instance;
  MonitorService._internal();

  late final Dio _dio;
  final AuthService _auth = AuthService();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}/api/monitors',
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _auth.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _auth.refreshAccessToken();
          if (refreshed) {
            error.requestOptions.headers['Authorization'] =
                'Bearer ${_auth.accessToken}';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<List<Map<String, dynamic>>> listMonitors() async {
    try {
      final response = await _dio.get('/');
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMonitor(int id) async {
    try {
      final response = await _dio.get('/$id');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>> createMonitor(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/', data: data);
      return {'success': true, 'monitor': response.data};
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail'] ?? 'Failed'
          : 'Failed';
      return {'success': false, 'error': detail.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMonitor(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/$id', data: data);
      return {'success': true, 'monitor': response.data};
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail'] ?? 'Failed'
          : 'Failed';
      return {'success': false, 'error': detail.toString()};
    }
  }

  Future<bool> deleteMonitor(int id) async {
    try {
      await _dio.delete('/$id');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> runCheck(int id) async {
    try {
      final response = await _dio.post('/$id/check');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(int id,
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/$id/history', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException {
      return [];
    }
  }
}
