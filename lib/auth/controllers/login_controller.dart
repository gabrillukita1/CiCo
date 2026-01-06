import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var email = ''.obs;
  var password = ''.obs;

  var userName = ''.obs;

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Email dan password harus diisi',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    final result = await _authService.login(email.value, password.value);

    isLoading.value = false;

    if (result != null) {
      // Ambil data user
      final userData = await _authService.getUser();
      if (userData != null) {
        userName.value = userData['name'] ?? userData['email'] ?? 'User';

        Get.snackbar(
          'Sukses',
          'Selamat datang, ${userName.value}!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed('/home');
      }
    }
  }

  // Fungsi logout 
  Future<void> logout() async {
    isLoading.value = true;
    await _authService.performLogout();
    isLoading.value = false;
    userName.value = '';
    Get.offAllNamed('/login');
  }
}
