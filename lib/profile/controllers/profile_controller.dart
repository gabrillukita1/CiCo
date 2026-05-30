import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final _authService = Get.find<AuthService>();

  final isLoading = true.obs;
  final profile = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final data = await _authService.getProfile();
      if (data == null) {
        AppNotifier.error('Gagal', 'Tidak dapat memuat profil. Coba lagi.');
      }
      profile.value = data;
    } catch (e) {
      AppNotifier.error('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() => AppNotifier.confirmAndLogout();
}
