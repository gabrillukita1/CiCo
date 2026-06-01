import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticate({
    String reason = 'Verifikasi menggunakan biometrik',
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    // Pre-check: device harus support authentication
    final bool deviceSupported = await _localAuth.isDeviceSupported();
    if (!deviceSupported) {
      _showNoCredentialDialog();
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // Tidak ada credentials (PIN/biometric) yang di-enroll
      if (e.code == 'NotEnrolled' || e.code == 'notEnrolled') {
        _showNoCredentialDialog();
        return false;
      }
      // Error lainnya (locked out, hardware error, dsb)
      AppNotifier.warning(
        'Gagal Verifikasi',
        e.message ?? 'Verifikasi gagal, coba lagi.',
      );
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showNoCredentialDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 10),
            Text(
              'Kunci Layar Diperlukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'HP ini belum memiliki kunci layar (PIN, pola, atau sidik jari).\n\n'
          'Buka Pengaturan → Keamanan → Kunci Layar, lalu atur PIN atau biometrik terlebih dahulu.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(),
            child: const Text('Mengerti',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
