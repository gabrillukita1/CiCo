import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:cico_project/app/routes/app_routes.dart';
import 'package:cico_project/core/config/app_config.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  late final Dio _dio;
  final _storage = GetStorage();
  bool _isRefreshing = false;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // Bypass SSL certificate verification (hanya untuk debug/emulator)
    if (kDebugMode) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isRetry = error.requestOptions.extra['isRetry'] == true;

          if (path == '/auth/login' || path == '/auth/refresh' || isRetry) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await refreshAccessToken();
            _isRefreshing = false;

            if (refreshed) {
              error.requestOptions.headers['Authorization'] =
                  'Bearer ${getToken()}';
              error.requestOptions.extra['isRetry'] = true;
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            } else {
              await logoutLocal();
              try {
                Get.offAllNamed(AppRoutes.login);
              } catch (_) {}
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ─── Token storage ────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async =>
      _storage.write('access_token', token);

  String? getToken() => _storage.read('access_token');

  String? getRefreshToken() => _storage.read('refresh_token');

  Future<void> logoutLocal() async {
    await _storage.remove('access_token');
    await _storage.remove('refresh_token');
  }

  // ─── Static helpers ───────────────────────────────────────────────────────

  /// Response format baru: { success: bool, statusCode?: int, message?: String|List }
  static bool isSuccess(Map<String, dynamic>? res) {
    if (res == null) return false;
    if (res.containsKey('success')) return res['success'] == true;
    // Legacy fallback
    if (res['error'] == true) return false;
    final statusCode = res['statusCode'] as int?;
    if (statusCode != null && statusCode >= 400) return false;
    return true;
  }

  /// Ekstrak message dari response — handle String maupun List (validation errors).
  static String extractMessage(dynamic message, {String fallback = 'Terjadi kesalahan'}) {
    if (message == null) return fallback;
    if (message is String) return message;
    if (message is List) return message.whereType<String>().join(', ');
    return fallback;
  }

  /// Buat error map standar dari DioException.
  static Map<String, dynamic> _errorFrom(DioException e, String fallback) => {
    'success': false,
    'statusCode': e.response?.statusCode,
    'message': extractMessage(e.response?.data?['message'], fallback: fallback),
  };

  // ─── Auth ─────────────────────────────────────────────────────────────────

  // LOGIN
  // Response: { success: true, data: { accessToken, refreshToken, user } }
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final token = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final user = data['user'] as Map<String, dynamic>;

      if (token != null) await saveToken(token);
      if (refreshToken != null) await _storage.write('refresh_token', refreshToken);

      return {'user': user, 'token': token};
    } on DioException catch (e) {
      String message = 'Login gagal. Periksa koneksi internet.';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Koneksi timeout. Server lambat atau tidak merespon.';
      } else if (e.response != null) {
        message = extractMessage(
          e.response?.data?['message'],
          fallback: 'Email atau password salah',
        );
      } else if (e.message?.contains('HandshakeException') == true) {
        message = 'Masalah sertifikat SSL (sudah dibypass untuk debug)';
      }

      AppNotifier.error('Login Gagal', message, duration: const Duration(seconds: 6));
      return null;
    } catch (e) {
      AppNotifier.error('Error', 'Terjadi kesalahan: $e');
      return null;
    }
  }

  // REFRESH TOKEN
  // Response: { success: true, data: { accessToken, refreshToken } }
  Future<bool> refreshAccessToken() async {
    final refreshToken = getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;
      if (newAccessToken != null) await saveToken(newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write('refresh_token', newRefreshToken);
      }
      return newAccessToken != null;
    } catch (_) {
      return false;
    }
  }

  // LOGOUT
  Future<bool> performLogout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // Logout tetap dilanjutkan meski API gagal
    } finally {
      await logoutLocal();
    }
    return true;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  // GET PROFILE
  // Response: { success: true, data: { id, name, email, role, phone, vehicleNumber, vehicleType, status } }
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Driver ───────────────────────────────────────────────────────────────

  // GET DRIVER DASHBOARD
  // Response: { success: true, data: { driverId, name, vehicleNumber, status, session? } }
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await _dio.get('/driver/dashboard');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException {
      return null;
    }
  }

  // CHECK-IN
  // Response: { success: true, message, data: { payment: { snapRedirectUrl } } }
  Future<Map<String, dynamic>?> checkIn({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/driver/checkin',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _errorFrom(e, 'Check-in gagal');
    }
  }

  // RETURN TO STANDBY
  // Response: { success: true, message: "Driver kembali ke pool. Status: Standby." }
  Future<Map<String, dynamic>?> returnToStandby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/driver/checkin/return',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _errorFrom(e, 'Gagal return to standby');
    }
  }

  // CHECKOUT
  // Response: { success: true, message: "Check-out berhasil" }
  Future<Map<String, dynamic>?> checkout() async {
    try {
      final response = await _dio.post('/driver/checkin/checkout');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      return _errorFrom(e, 'Checkout gagal');
    }
  }

  // GET CHECKIN HISTORY
  // Response: { success: true, data: [...], total, page, limit, totalPages }
  Future<Map<String, dynamic>?> getCheckinHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (startDate != null) params['from'] = startDate.toUtc().toIso8601String();
      if (endDate != null) params['to'] = endDate.toUtc().toIso8601String();
      final response = await _dio.get(
        '/driver/checkin/history',
        queryParameters: params,
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
