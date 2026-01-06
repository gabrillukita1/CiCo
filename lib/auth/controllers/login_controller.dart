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
      final user = result['user'];
      userName.value = user['name'] ?? user['email'] ?? 'User';

      Get.snackbar(
        'Sukses!',
        'Selamat datang, ${userName.value} 👋',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      Get.dialog(
        AlertDialog(
          title: const Text('Login Berhasil!'),
          content: Text('Halo ${userName.value}!'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
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
