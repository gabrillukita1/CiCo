import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var email = ''.obs;
  var password = ''.obs;

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
      final user = result['user'];

      Get.offAllNamed(
        '/home',
        arguments: {'name': user['name'], 'email': user['email']},
      );
    }
  }

  Future<void> logout() async {
    isLoading.value = true;

    await _authService.performLogout();

    isLoading.value = false;

    Get.offAllNamed('/login');
  }
}
