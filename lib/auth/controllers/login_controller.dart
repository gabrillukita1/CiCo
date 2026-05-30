import 'package:cico_project/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/widgets/app_notifier.dart';

import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var appVersion = ''.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = 'v${info.version}';
    } catch (_) {
      appVersion.value = 'v1.0.0';
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    final emailText = emailController.text.trim();
    final passwordText = passwordController.text;

    if (emailText.isEmpty || passwordText.isEmpty) {
      AppNotifier.warning('Validasi', 'Email dan password harus diisi');
      return;
    }
    if (!GetUtils.isEmail(emailText)) {
      AppNotifier.warning('Validasi', 'Format email tidak valid');
      return;
    }

    isLoading.value = true;
    final result = await _authService.login(emailText, passwordText);
    isLoading.value = false;

    if (result != null) {
      TextInput.finishAutofillContext();
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
