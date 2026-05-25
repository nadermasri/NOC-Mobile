import 'package:dio/dio.dart';
import 'package:pocket_noc/core/constants/app_constants.dart';
import 'package:pocket_noc/core/services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final AuthService _auth = AuthService();

  void init({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '${AppConstants.baseUrl}${AppConstants.apiPrefix}',
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _auth.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> explainResult(
      Map<String, dynamic> diagnosticData) async {
    try {
      final response = await _dio.post(
        '/ai/explain',
        data: diagnosticData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Failed to get explanation',
      };
    }
  }

  Future<Map<String, dynamic>> saveReport(
      Map<String, dynamic> reportData) async {
    try {
      final response = await _dio.post(
        '/reports/save',
        data: reportData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Failed to save report',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final response = await _dio.get('/reports');
      return (response.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException {
      return [];
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
