import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackendApiClient {
  BackendApiClient({required FirebaseAuth firebaseAuth, Dio? dio})
    : _firebaseAuth = firebaseAuth,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _firebaseAuth.currentUser?.getIdToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
      ),
    );
  }

  static const _baseUrl = String.fromEnvironment(
    'STEALTHERA_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>('/health/dashboard');

    return response.data ?? <String, dynamic>{};
  }
}
