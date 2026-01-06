import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';

class AuthService {
  late final Dio _dio;
  final _storage = GetStorage();

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://cico-api.my.id/api',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));

    // Bypass SSL certificate verification (DEVELOPMENT/EMULATOR)
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return null;
    };
  }

  // Simpan token
  Future<void> saveToken(String token) async {
    await _storage.write('access_token', token);
  }

  // Ambil token
  String? getToken() {
    return _storage.read('access_token');
  }

  // Hapus token
  Future<void> logoutLocal() async {
    await _storage.remove('access_token');
  }

  // Set header Bearer
  void _setAuthHeader() {
    String? token = getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['access_token'] as String?;
        final user = data['user'] as Map<String, dynamic>;

        if (token != null) {
          await saveToken(token);
        }

        return {
          'user': user,
          'token': token,
        };
      }
    } on DioException catch (e) {
      String message = 'Login gagal. Periksa koneksi internet.';

      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        message = 'Koneksi timeout. Server lambat atau tidak merespon.';
      } else if (e.response != null) {
        message = e.response?.data['message'] ?? 'Email atau password salah';
      } else if (e.message?.contains('HandshakeException') == true) {
        message = 'Masalah sertifikat SSL (sudah dibypass untuk debug)';
      }

      Get.snackbar(
        'Login Gagal',
        message,
        backgroundColor: 
        Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );

      print('DIO ERROR: $e');
      return null;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
      print('UNEXPECTED ERROR: $e');
      return null;
    }
    return null;
  }

  // GET USER (/me) - opsional
  Future<Map<String, dynamic>?> getUser() async {
    _setAuthHeader();
    try {
      final response = await _dio.get('/me');
      if (response.statusCode == 200) {
        return response.data['user'] as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logoutLocal();
        Get.offAllNamed('/login');
      }
      print('GET USER ERROR: $e');
      return null;
    }
    return null;
  }

  // LOGOUT
  Future<bool> performLogout() async {
    _setAuthHeader();
    try {
      await _dio.post('/logout');
    } on DioException catch (e) {
      print('LOGOUT ERROR (ignored): $e');
    } finally {
      await logoutLocal();
    }
    return true;
  }
}