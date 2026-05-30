import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/widgets/app_notifier.dart';

import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoading = false.obs;
  var email = ''.obs;
  var password = ''.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      AppNotifier.warning('Validasi', 'Email dan password harus diisi');
      return;
    }
    if (!GetUtils.isEmail(email.value)) {
      AppNotifier.warning('Validasi', 'Format email tidak valid');
      return;
    }

    isLoading.value = true;
    final result = await _authService.login(email.value, password.value);
    isLoading.value = false;

    if (result != null) {
      TextInput.finishAutofillContext();
      Get.offAllNamed('/home');
    }
  }

}
