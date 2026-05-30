import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:cico_project/core/config/app_config.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';

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

    // Bypass SSL certificate verification (DEVELOPMENT/EMULATOR)
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return null;
        };

    _dio.interceptors.add(
      InterceptorsWrapper(
        // Otomatis tambah Authorization header di setiap request
        onRequest: (options, handler) {
          final token = getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Tangkap 401, coba refresh token, retry request
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isRetry = error.requestOptions.extra['isRetry'] == true;

          // Skip: endpoint login/refresh atau sudah pernah retry
          if (path == '/auth/login' ||
              path == '/auth/refresh' ||
              isRetry) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await refreshAccessToken();
            _isRefreshing = false;

            if (refreshed) {
              // Retry request asal dengan token baru
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
              // Refresh gagal → logout
              await logoutLocal();
              try {
                Get.offAllNamed('/login');
              } catch (_) {
                // App belum terinisialisasi (dipanggil saat startup)
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Simpan token
  Future<void> saveToken(String token) async {
    await _storage.write('access_token', token);
  }

  // Ambil token
  String? getToken() {
    return _storage.read('access_token');
  }

  // Ambil refresh token
  String? getRefreshToken() {
    return _storage.read('refresh_token');
  }

  // Hapus token
  Future<void> logoutLocal() async {
    await _storage.remove('access_token');
    await _storage.remove('refresh_token');
  }

  // LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['accessToken'] as String?;
        final refreshToken = response.data['refreshToken'] as String?;
        final user = response.data['user'] as Map<String, dynamic>;

        if (token != null) {
          await saveToken(token);
        }
        if (refreshToken != null) {
          await _storage.write('refresh_token', refreshToken);
        }
        return {'user': user, 'token': token};
      }
    } on DioException catch (e) {
      String message = 'Login gagal. Periksa koneksi internet.';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Koneksi timeout. Server lambat atau tidak merespon.';
      } else if (e.response != null) {
        final data = e.response?.data;
        if (data is Map) {
          message = data['message'] ?? 'Email atau password salah';
        }
      } else if (e.message?.contains('HandshakeException') == true) {
        message = 'Masalah sertifikat SSL (sudah dibypass untuk debug)';
      }

      AppNotifier.error(
        'Login Gagal',
        message,
        duration: const Duration(seconds: 6),
      );
      return null;
    } catch (e) {
      AppNotifier.error('Error', 'Terjadi kesalahan: $e');
      return null;
    }
    return null;
  }

  // REFRESH TOKEN
  Future<bool> refreshAccessToken() async {
    final refreshToken = getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;
        if (newAccessToken != null) await saveToken(newAccessToken);
        if (newRefreshToken != null) {
          await _storage.write('refresh_token', newRefreshToken);
        }
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  // VALIDATE TOKEN
  Future<bool> isTokenValid() async {
    final token = getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _dio.get('/auth/me');
      return response.statusCode == 200;
    } catch (_) {
      // Interceptor sudah handle refresh & logout otomatis
      return false;
    }
  }

  // GET USER
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Interceptor sudah handle refresh & redirect otomatis
    }
    return null;
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

  // GET PROFILE
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // GET CHECKIN HISTORY
  Future<Map<String, dynamic>?> getCheckinHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (startDate != null) {
        params['from'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        params['to'] = endDate.toUtc().toIso8601String();
      }
      final response = await _dio.get(
        '/driver/checkin/history',
        queryParameters: params,
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET PAYMENT HISTORY
  Future<Map<String, dynamic>?> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/driver/payments',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // GET DISPATCH HISTORY
  Future<Map<String, dynamic>?> getDispatchHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/driver/dispatch',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // CHECK-IN
  Future<Map<String, dynamic>?> checkIn({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/driver/checkin',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'error': true,
        'message': e.response?.data?['message'] ?? 'Check-in gagal',
        'statusCode': e.response?.statusCode,
      };
    }
  }

  // GET DRIVER DASHBOARD
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await _dio.get('/driver/dashboard');
      return response.data as Map<String, dynamic>;
    } on DioException {
      return null;
    }
  }

  // RETURN TO STANDBY
  Future<Map<String, dynamic>?> returnToStandby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/driver/checkin/return',
        data: {'latitude': latitude, 'longitude': longitude},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'error': true,
        'message': e.response?.data?['message'] ?? 'Gagal return to standby',
        'statusCode': e.response?.statusCode,
      };
    }
  }

  // CHECKOUT
  Future<Map<String, dynamic>?> checkout() async {
    try {
      final response = await _dio.post('/driver/checkin/checkout');
      // print('CHECKOUT API SUCCESS: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      // print('CHECKOUT API ERROR - Status: ${e.response?.statusCode}');
      // print('CHECKOUT API ERROR - Message: ${e.response?.data['message']}');
      return {
        'success': false,
        'message':
            e.response?.data['message'] ??
            'Checkout gagal (kode ${e.response?.statusCode})',
      };
    }
  }
}
