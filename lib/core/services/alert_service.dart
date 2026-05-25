import 'package:dio/dio.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/services/auth_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  late final Dio _dio;
  final AuthService _auth = AuthService();

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.baseUrl}/api/alerts',
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

  Future<List<Map<String, dynamic>>> listAlerts({
    String? status,
    String? severity,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) params['status'] = status;
      if (severity != null) params['severity'] = severity;
      final response = await _dio.get('/', queryParameters: params);
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/unread-count');
      return (response.data as Map)['count'] as int? ?? 0;
    } on DioException {
      return 0;
    }
  }

  Future<bool> acknowledgeAlert(int id) async {
    try {
      await _dio.put('/$id', data: {'status': 'acknowledged'});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> resolveAlert(int id) async {
    try {
      await _dio.put('/$id', data: {'status': 'resolved'});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<int> acknowledgeAll() async {
    try {
      final response = await _dio.post('/acknowledge-all');
      return (response.data as Map)['acknowledged'] as int? ?? 0;
    } on DioException {
      return 0;
    }
  }
}
