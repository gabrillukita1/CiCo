import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthService {
  final Dio _dio = Dio();
  final _storage = GetStorage();

  final String baseUrl = 'https://cico-api.my.id/api';

  // Simpan token
  Future<void> saveToken(String token) async {
    await _storage.write('access_token', token);
  }

  // Ambil token
  String? getToken() {
    return _storage.read('access_token');
  }

  // Hapus token (logout)
  Future<void> logout() async {
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
        '$baseUrl/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['access_token'];
        await saveToken(token);
        return response.data;
      }
    } on DioException catch (e) {
      String message = 'Login gagal';
      if (e.response != null) {
        message = e.response?.data['message'] ?? 'Email atau password salah';
      }
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
    return null;
  }

  // GET AUTHENTICATED USER (/me)
  Future<Map<String, dynamic>?> getUser() async {
    _setAuthHeader();
    try {
      final response = await _dio.get('$baseUrl/me');
      if (response.statusCode == 200) {
        return response
            .data['user']; // Sesuaikan dengan struktur response API kamu
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logout();
        Get.offAllNamed('/login'); // Nanti kita setup route
      }
      return null;
    }
    return null;
  }

  // LOGOUT
  Future<bool> performLogout() async {
    _setAuthHeader();
    try {
      await _dio.post('$baseUrl/logout');
      await logout();
      return true;
    } on DioException {
      await logout();
      return true;
    }
  }
}
