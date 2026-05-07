import 'dart:async';

import 'package:cico_project/auth/services/biometric_service.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:cico_project/home/views/snap_payment_page.dart';
import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeController extends GetxController {
  final AuthService _authService = AuthService();

  final userName = ''.obs;
  final userEmail = ''.obs;

  final startTime = ''.obs;
  final endTime = ''.obs;

  final checkInStatus = ''.obs;
  final isCheckedIn = false.obs;
  final statusText = 'Off'.obs;
  final isProcessing = false.obs;

  final snapToken = ''.obs;

  final biometricService = BiometricService();

  final currentPosition = Rxn<Position>();
  final currentAddress = ''.obs;

  Timer? _statusPollingTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      userName.value = args['name'].toString();
      userEmail.value = args['email'].toString();
    }
    loadCheckInStatus();
    fetchCurrentLocation();
  }

  @override
  void onClose() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    super.onClose();
  }

  Future<void> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppNotifier.warning("Lokasi", "Lokasi tidak aktif");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppNotifier.warning("Lokasi", "Izin lokasi ditolak");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        AppNotifier.error("Lokasi", "Izin lokasi ditolak permanen");
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = pos;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String?> parts = [
          // place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();

        currentAddress.value = parts.join(', ');
      } else {
        currentAddress.value = "Alamat tidak ditemukan";
      }
    } catch (e) {
      AppNotifier.error("Error", "Gagal ambil lokasi: $e");
      currentAddress.value = "Gagal mendapatkan alamat";
    }
  }

  Future<void> loadCheckInStatus() async {
    final previousStatus = checkInStatus.value;
    final session = await _authService.getCheckInSession();
    if (session == null || session['status'] != 'success') {
      _resetToIdle();
      return;
    }
    final checkinData =
        session['data']?['checkin_session'] as Map<String, dynamic>?;

    // Format time
    final rawStart = checkinData?['start_time'];
    final rawEnd = checkinData?['end_time'];
    startTime.value = _formatTime(rawStart);
    endTime.value = _formatTime(rawEnd);

    if (checkinData == null) {
      // print('→ Tidak ada checkin_session di response');
      _resetToIdle();
      return;
    }
    final serverStatus =
        (checkinData['status'] as String?)?.toLowerCase() ?? 'none';
    checkInStatus.value = serverStatus;

    // print("checkInStatus: ${checkInStatus.value}");

    switch (serverStatus) {
      // Active
      case 'active':
        isCheckedIn.value = true;
        statusText.value = 'Aktif';
        snapToken.value = '';
        break;
      // Pending payment
      case 'waiting_for_payment':
        isCheckedIn.value = false;
        statusText.value = 'Menunggu Pembayaran';
        final token =
            (checkinData['snap_token'] ?? checkinData['token'] ?? '') as String;
        if (token.isNotEmpty && token != snapToken.value) {
          snapToken.value = token;
        }
        _startPollingCheckInSession();
        break;
      // Expired
      case 'expired':
      default:
        _resetToIdle();
        break;
    }

    // Notifikasi transisi ke aktif
    if (previousStatus != 'active' && checkInStatus.value == 'active') {
      AppNotifier.success(
        'Pembayaran Berhasil!',
        'Sesi aktif sampai ${checkinData['end_time'] ?? 'waktu tertentu'}',
        duration: const Duration(seconds: 5),
      );
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--:--';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  void _resetToIdle() {
    isCheckedIn.value = false;
    statusText.value = 'Off';
    checkInStatus.value = 'expired';
    snapToken.value = '';
    startTime.value = '--:--';
    endTime.value = '--:--';
  }

  Future<void> refreshSessionStatus() async {
    try {
      await loadCheckInStatus();
    } catch (e) {
      // print('Refresh status error: $e');
    }
  }

  Future<void> refreshWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await refreshSessionStatus();
  }

  void _startPollingCheckInSession() {
    _statusPollingTimer?.cancel();

    if (checkInStatus.value == 'waiting_for_payment') {
      _statusPollingTimer = Timer.periodic(const Duration(seconds: 8), (
        timer,
      ) async {
        await refreshSessionStatus();
        if (checkInStatus.value != 'waiting_for_payment') {
          timer.cancel();
        }
      });
    }
  }

  Future<void> toggleCheckInOut() async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      await refreshSessionStatus();
      // WEBVIEW PAYMENT
      if (checkInStatus.value == 'waiting_for_payment') {
        await retryPay();
        final result = await Get.to(
          () => SnapPaymentPage(snapToken: snapToken.value),
        );
        await _handleSnapPaymentResult(result);
        return;
      }
      // CHECK-IN
      final bool shouldCheckOut = checkInStatus.value == 'active';
      if (!shouldCheckOut) {
        // BIOMETRIC AUTHENTICATION
        final bool canAuth = await requestBiometricForCheckIn();
        if (!canAuth) return;
        final res = await _authService.checkIn();
        if (!_isApiSuccess(res)) {
          final msg = res?['message'] ?? res?['error'] ?? 'Gagal check-in';
          if (msg.toLowerCase().contains('waiting_for_payment') ||
              msg.toLowerCase().contains('active')) {
            await refreshSessionStatus();
          } else {
            AppNotifier.error(
              'Gagal Check-In',
              msg,
            );
            return;
          }
        }
        // WAITING FOR PAYMENT
        await refreshSessionStatus();
        if (checkInStatus.value == 'waiting_for_payment') {
          if (snapToken.value.isEmpty) {
            await retryPay();
          }
          await Future.delayed(const Duration(milliseconds: 200));
          final result = await Get.to(
            () => SnapPaymentPage(snapToken: snapToken.value),
          );
          await _handleSnapPaymentResult(result);
          return;
        }
        if (checkInStatus.value == 'active') {
          AppNotifier.success(
            'Check-In Berhasil',
            'Sesi langsung aktif',
          );
        }
        return;
      }
      // CHECK-OUT
      final confirm = await AppNotifier.confirmDialog(
        title: 'Konfirmasi Check-Out',
        message: 'Apakah kamu yakin ingin mengakhiri sesi check-in ini?',
        confirmText: 'Ya, Check-Out',
        type: AppNoticeType.error,
      );
      if (!confirm) return;
      final res = await _authService.checkout();
      if (!_isApiSuccess(res)) {
        final msg =
            res?['message'] ?? res?['error'] ?? 'Check-out ditolak server';
        AppNotifier.error('Gagal Check-Out', msg);
        return;
      }

      // Reset lokal
      isCheckedIn.value = false;
      checkInStatus.value = 'expired';
      snapToken.value = '';
      statusText.value = 'Off';

      AppNotifier.info(
        'Check-Out Berhasil',
        res?['message'] ?? 'Sesi telah diakhiri',
      );
      await refreshWithDelay();
    } catch (e) {
      // print('EXCEPTION toggleCheckInOut: $e');
      // print(stack);
      AppNotifier.error(
        'Error',
        'Gagal proses: $e',
      );
    } finally {
      isProcessing.value = false;
    }
  }

  bool _isApiSuccess(Map<String, dynamic>? res) {
    if (res == null) return false;
    final code = res['response_code']?.toString();
    final statusLower = (res['status'] as String?)?.toLowerCase();
    final successFlag = res['success'] == true;
    final isSuccessPattern =
        successFlag ||
        statusLower == 'success' ||
        code == '200' ||
        code == '201';
    final hasErrorIndication =
        res.containsKey('error') ||
        statusLower == 'error' ||
        statusLower == 'failed' ||
        (code != null && code.startsWith('4'));
    if (isSuccessPattern && !hasErrorIndication) {
      return true;
    }
    return false;
  }

  Future<void> retryPay() async {
    // if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      final res = await _authService.pay();
      await _handlePayResponse(res);
    } catch (e) {
      AppNotifier.error('Error', 'Gagal membuat pembayaran: $e');
    } finally {
      isProcessing.value = false;
      // await refreshSessionStatus();
    }
  }

  Future<void> _handlePayResponse(Map<String, dynamic>? res) async {
    if (res == null) {
      AppNotifier.error('Error', 'Tidak ada respon server');
      return;
    }

    if (_isApiSuccess(res)) {
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final token = (data['snap_token'] ?? data['token']) as String;
      if (token.isNotEmpty) {
        snapToken.value = token;
        checkInStatus.value = 'waiting_for_payment';
        print('Token berhasil: $token');
        AppNotifier.success(
          'Sukses',
          'QRIS siap dibayar',
        );
      } else {
        AppNotifier.warning('Peringatan', 'Token pembayaran kosong');
      }
    } else {
      final msg = res['message'] ?? 'Gagal membuat pembayaran';
      // print('Pay gagal: $msg');
      AppNotifier.error('Gagal', msg);
    }
  }

  Future<void> _handleSnapPaymentResult(dynamic result) async {
    if (result == 'success') {
      await refreshSessionStatus();
      if (checkInStatus.value == 'active') {
        AppNotifier.success(
          'Pembayaran Berhasil',
          'Pembayaran berhasil dan sesi check-in kamu sudah aktif.',
        );
      } else {
        AppNotifier.success(
          'Pembayaran Berhasil',
          'Transaksi sukses. Status sesi sedang diperbarui otomatis.',
        );
      }
      return;
    }
    if (result == 'pending') {
      AppNotifier.warning(
        'Pembayaran Pending',
        'Transaksi masih diproses. Cek kembali beberapa saat lagi.',
      );
      return;
    }
    if (result == 'failed') {
      AppNotifier.error(
        'Pembayaran Gagal',
        'Transaksi tidak berhasil. Silakan coba lagi.',
      );
      return;
    }
    if (result == 'closed') {
      AppNotifier.warning(
        'Pembayaran Dibatalkan',
        'Kamu menutup halaman pembayaran sebelum selesai.',
      );
    }
  }

  Future<void> logout() async {
    final confirm = await AppNotifier.confirmDialog(
      title: 'Konfirmasi Logout',
      message: 'Apakah kamu yakin ingin logout dari aplikasi?',
      confirmText: 'Ya, Logout',
      type: AppNoticeType.error,
    );
    if (!confirm) {
      return;
    }
    try {
      await _authService.performLogout();
    } finally {
      userName.value = '';
      Get.offAllNamed('/login');
    }
  }

  Future<bool> requestBiometricForCheckIn() async {
    try {
      final bool authenticated = await biometricService.authenticate(
        reason: 'Konfirmasi check-in',
      );
      if (authenticated) {
        return true;
      } else {
        AppNotifier.warning(
          'Verifikasi Gagal',
          'Autentikasi biometrik dibutuhkan untuk check-in',
          duration: const Duration(seconds: 4),
        );
        return false;
      }
    } catch (e) {
      AppNotifier.error(
        'Error Biometrik',
        'Gagal memverifikasi identitas: ${e.toString().split('\n').first}',
        duration: const Duration(seconds: 5),
      );
      // print('Biometric error: $e');
      return false;
    }
  }

  Future<void> manualRefresh() async {
    try {
      await loadCheckInStatus();
    } catch (e) {
      AppNotifier.error(
        'Error',
        'Gagal refresh status',
      );
    }
  }
}
