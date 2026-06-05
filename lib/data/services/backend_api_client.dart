import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/config/app_config.dart';

class BackendApiClient {
  BackendApiClient({required FirebaseAuth firebaseAuth, Dio? dio})
    : _firebaseAuth = firebaseAuth,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.requestTimeout,
              receiveTimeout: AppConfig.requestTimeout,
            ),
          ) {
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (object) => developer.log(
          object.toString(),
          name: 'BackendApiClient',
        ),
        retries: 3,
        retryDelays: const [
          Duration(seconds: 2),
          Duration(seconds: 5),
          Duration(seconds: 10),
        ],
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _firebaseAuth.currentUser?.getIdToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '[BackendApiClient] ${response.requestOptions.method} '
            '${response.requestOptions.uri} -> ${response.statusCode}',
            name: 'BackendApiClient',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          developer.log(
            '[BackendApiClient] ${error.requestOptions.method} '
            '${error.requestOptions.uri} failed: '
            '${error.response?.statusCode ?? 'no-status'} ${error.message}',
            name: 'BackendApiClient',
          );
          if (error.response?.data != null) {
            developer.log(
              '[BackendApiClient] response body: ${error.response?.data}',
              name: 'BackendApiClient',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  final FirebaseAuth _firebaseAuth;
  final Dio _dio;

  Future<Map<String, dynamic>> getDashboard() async {
    return _getData('/health/dashboard');
  }

  Future<Map<String, dynamic>> getSettings() async {
    return _getData('/settings');
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/settings',
      data: updates,
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> syncReadings(
    List<Map<String, dynamic>> readings,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/health/sync',
      data: {'readings': readings},
    );

    return _extractData(response);
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final response = await _dio.get<Map<String, dynamic>>('/alerts');
    final data = response.data?['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> updateAlertStatus(
    String alertId,
    String status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/alerts/$alertId',
      data: {'status': status},
    );

    return _extractData(response);
  }

  Future<Map<String, dynamic>> _getData(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);

    return _extractData(response);
  }

  Map<String, dynamic> _extractData(Response<Map<String, dynamic>> response) {
    final payload = response.data ?? <String, dynamic>{};
    final data = payload['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }
}
