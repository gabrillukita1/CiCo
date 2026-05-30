import 'package:flutter/services.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({
    String reason = 'Verifikasi menggunakan biometrik',
    bool biometricOnly = true,
    bool stickyAuth = true,
  }) async {
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
      AppNotifier.warning(
        'Gagal Verifikasi',
        'Biometric gagal: ${e.message ?? 'Coba lagi'}',
      );
      return false;
    } catch (_) {
      return false;
    }
  }
}
