import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final _authService = AuthService();

  final isLoading = true.obs;
  final profile = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    final data = await _authService.getProfile();
    profile.value = data;
    isLoading.value = false;
  }

  Future<void> logout() async {
    final confirm = await AppNotifier.confirmDialog(
      title: 'Konfirmasi Logout',
      message: 'Apakah kamu yakin ingin logout dari aplikasi?',
      confirmText: 'Ya, Logout',
      type: AppNoticeType.error,
    );
    if (!confirm) return;
    await _authService.performLogout();
    Get.offAllNamed('/login');
  }
}
