import 'package:cico_project/core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum AppNoticeType { success, error, warning, info }

class AppNotifier {
  const AppNotifier._();

  static void success(String title, String message, {Duration duration = const Duration(seconds: 1, milliseconds: 500)}) => 
      _show(title, message, type: AppNoticeType.success, duration: duration);

  static void error(String title, String message, {Duration duration = const Duration(seconds: 1, milliseconds: 500)}) => 
      _show(title, message, type: AppNoticeType.error, duration: duration);

  static void warning(String title, String message, {Duration duration = const Duration(seconds: 1, milliseconds: 500)}) => 
      _show(title, message, type: AppNoticeType.warning, duration: duration);

  static void info(String title, String message, {Duration duration = const Duration(seconds: 1, milliseconds: 500)}) => 
      _show(title, message, type: AppNoticeType.info, duration: duration);

  static void _show(
    String title,
    String message, {
    required AppNoticeType type,
    required Duration duration,
  }) {
    final style = _styleFor(type);

    Get.closeAllSnackbars();
    Get.snackbar(
      '', 
      '',
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13,
          height: 1.4,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      icon: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(style.icon, color: Colors.white, size: 22),
      ),
      shouldIconPulse: true,
      backgroundColor: style.backgroundColor.withOpacity(0.95),
      colorText: Colors.white,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        BoxShadow(
          color: style.backgroundColor.withOpacity(0.4),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      overlayBlur: 1.2,
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  static Future<bool> confirmDialog({
    required String title,
    required String message,
    String cancelText = 'Batal',
    String confirmText = 'Lanjutkan',
    AppNoticeType type = AppNoticeType.warning,
  }) async {
    final style = _styleFor(type);

    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: style.backgroundColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.backgroundColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Get.back(result: false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: style.backgroundColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  static _AppNoticeStyle _styleFor(AppNoticeType type) {
    switch (type) {
      case AppNoticeType.success:
        return const _AppNoticeStyle(
          backgroundColor: AppColors.active,
          icon: Icons.check_circle_rounded,
        );
      case AppNoticeType.error:
        return const _AppNoticeStyle(
          backgroundColor: AppColors.inactive,
          icon: Icons.error_rounded,
        );
      case AppNoticeType.warning:
        return const _AppNoticeStyle(
          backgroundColor: AppColors.waiting,
          icon: Icons.warning_rounded,
        );
      case AppNoticeType.info:
        return const _AppNoticeStyle(
          backgroundColor: AppColors.primary,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _AppNoticeStyle {
  final Color backgroundColor;
  final IconData icon;

  const _AppNoticeStyle({required this.backgroundColor, required this.icon});
}