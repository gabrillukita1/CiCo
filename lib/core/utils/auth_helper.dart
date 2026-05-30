import 'package:cico_project/app/routes/app_routes.dart';
import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:get/get.dart';

/// Helper logout terpusat — memisahkan UI/navigasi dari AuthService (SRP),
/// dan menghindari circular import antara AppNotifier ↔ AuthService.
class AuthHelper {
  AuthHelper._();

  static Future<void> confirmAndLogout() async {
    final confirm = await AppNotifier.confirmDialog(
      title: 'Konfirmasi Logout',
      message: 'Apakah kamu yakin ingin logout dari aplikasi?',
      confirmText: 'Ya, Logout',
      type: AppNoticeType.error,
    );
    if (!confirm) return;
    try {
      await Get.find<AuthService>().performLogout();
    } finally {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
