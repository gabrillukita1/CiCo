import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cico_project/auth/services/biometric_service.dart';
import 'package:cico_project/core/utils/date_utils.dart' as tz;
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:cico_project/home/views/snap_payment_page.dart';
import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final AuthService _authService = Get.find<AuthService>();

  final isInitializing = true.obs;
  final userName = ''.obs;
  final vehicleNumber = ''.obs;

  final startTime = ''.obs;
  final endTime = ''.obs;

  final checkInStatus = ''.obs;
  final isProcessing = false.obs;

  final remainingMinutes = Rxn<int>();

  final biometricService = Get.find<BiometricService>();

  final currentPosition = Rxn<Position>();
  final currentAddress = ''.obs;

  Timer? _statusPollingTimer;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initDashboard();
    fetchCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      manualRefresh();
    }
  }

  Future<void> _initDashboard() async {
    isInitializing.value = true;
    await loadCheckInStatus();
    isInitializing.value = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
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
    final dashboard = await _authService.getDashboard();
    if (dashboard == null) {
      _resetToIdle();
      return;
    }

    // Update data driver dari dashboard
    final name = dashboard['name'] as String? ?? '';
    if (name.isNotEmpty) userName.value = name;
    final vehicle = dashboard['vehicleNumber'] as String? ?? '';
    if (vehicle.isNotEmpty) vehicleNumber.value = vehicle;

    final serverStatus =
        (dashboard['status'] as String?)?.toLowerCase() ?? 'offline';
    checkInStatus.value = serverStatus;

    final session = dashboard['session'] as Map<String, dynamic>?;

    // Format start/end time dari session
    startTime.value = tz.formatTime(session?['checkinAt']);
    endTime.value = tz.formatTime(session?['expiresAt']);
    remainingMinutes.value = session?['remainingMinutes'] as int?;

    switch (serverStatus) {
      case 'on_duty':
      case 'standby':
        break;
      case 'pending_payment':
        _startPollingCheckInSession();
        break;
      case 'offline':
      default:
        _resetToIdle();
        break;
    }

    // Mulai countdown lokal setiap menit jika ada sisa waktu
    _countdownTimer?.cancel();
    if (remainingMinutes.value != null && remainingMinutes.value! > 0) {
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        final current = remainingMinutes.value;
        if (current != null && current > 0) {
          remainingMinutes.value = current - 1;
        } else {
          _countdownTimer?.cancel();
        }
      });
    }

    // Notifikasi transisi ke on_duty
    if (previousStatus != 'on_duty' && checkInStatus.value == 'on_duty') {
      AppNotifier.success(
        'Pembayaran Berhasil!',
        'Sesi kerja Anda sudah aktif.',
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _resetToIdle() {
    checkInStatus.value = 'offline';
    startTime.value = '--:--';
    endTime.value = '--:--';
    remainingMinutes.value = null;
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

    if (checkInStatus.value == 'pending_payment') {
      _statusPollingTimer = Timer.periodic(const Duration(seconds: 8), (
        timer,
      ) async {
        await refreshSessionStatus();
        if (checkInStatus.value != 'pending_payment') {
          timer.cancel();
        }
      });
    }
  }

  Future<void> toggleCheckInOut() async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      // Gunakan status lokal yang sudah di-sync oleh polling
      // Tidak perlu refresh di sini agar swipe responsif dan tidak reset status
      final status = checkInStatus.value;

      // ─── LANJUT PEMBAYARAN ───────────────────────────────────────────────
      if (status == 'pending_payment') {
        await _doRetryPayment();
        return;
      }

      // ─── CHECK-OUT ───────────────────────────────────────────────────────
      if (status == 'standby') {
        await _doCheckOut();
        return;
      }

      // ─── CHECK-IN ────────────────────────────────────────────────────────
      await _doCheckIn();
    } catch (e) {
      AppNotifier.error('Error', 'Gagal proses: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _doCheckIn() async {
    // 1. Biometric wajib
    final bool authenticated = await requestBiometricForCheckIn();
    if (!authenticated) return;

    // 2. Lokasi wajib
    Position? pos = currentPosition.value;
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
        currentPosition.value = pos;
      } catch (_) {
        AppNotifier.error(
          'Lokasi Tidak Tersedia',
          'Aktifkan GPS dan pastikan izin lokasi sudah diberikan, lalu coba lagi.',
          duration: const Duration(seconds: 5),
        );
        return;
      }
    }

    // 3. Request check-in
    final res = await _authService.checkIn(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!_isApiSuccess(res)) {
      AppNotifier.error('Gagal Check-In', res?['message'] ?? 'Gagal check-in');
      await refreshSessionStatus();
      return;
    }

    // 4. Ambil redirectUrl dari response (handle dua format)
    final payment = res?['payment'] as Map<String, dynamic>?;
    final redirectUrl = res?['redirect_url'] as String?
        ?? payment?['snapRedirectUrl'] as String?
        ?? '';

    // 5. Buka payment jika ada redirectUrl, atau refresh status
    if (redirectUrl.isNotEmpty) {
      await refreshSessionStatus();
      final result = await Get.to(() => SnapPaymentPage(redirectUrl: redirectUrl));
      await _handleSnapPaymentResult(result);
    } else {
      await refreshSessionStatus();
      if (checkInStatus.value == 'on_duty' || checkInStatus.value == 'standby') {
        AppNotifier.success('Check-In Berhasil', 'Sesi langsung aktif');
      }
    }
  }

  // Retry payment: panggil /driver/checkin lagi untuk dapat redirect_url baru
  Future<void> _doRetryPayment() async {
    Position? pos = currentPosition.value;
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(const Duration(seconds: 5));
        currentPosition.value = pos;
      } catch (_) {
        AppNotifier.error('Lokasi Tidak Tersedia', 'Aktifkan GPS lalu coba lagi.');
        return;
      }
    }

    final res = await _authService.checkIn(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!_isApiSuccess(res)) {
      AppNotifier.error('Gagal', res?['message'] ?? 'Gagal mendapatkan halaman pembayaran');
      return;
    }

    final paymentData = res?['payment'] as Map<String, dynamic>?;
    final redirectUrl = res?['redirect_url'] as String?
        ?? paymentData?['snapRedirectUrl'] as String?
        ?? '';
    if (redirectUrl.isEmpty) {
      AppNotifier.warning('Pembayaran', 'URL pembayaran tidak ditemukan.');
      return;
    }

    final result = await Get.to(() => SnapPaymentPage(redirectUrl: redirectUrl));
    await _handleSnapPaymentResult(result);
  }

  /// Dipanggil dari SwipeButton Return saat status on_duty
  Future<void> returnToStandby() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      await _doReturnToStandby();
    } catch (e) {
      AppNotifier.error('Error', 'Gagal proses: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Dipanggil dari SwipeButton Check-Out saat status on_duty
  Future<void> checkOutFromDuty() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      await _doCheckOut();
    } catch (e) {
      AppNotifier.error('Error', 'Gagal proses: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _doReturnToStandby() async {
    // Ambil lokasi
    Position? pos = currentPosition.value;
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
        currentPosition.value = pos;
      } catch (_) {
        AppNotifier.error(
          'Lokasi Tidak Tersedia',
          'Aktifkan GPS dan pastikan izin lokasi sudah diberikan, lalu coba lagi.',
          duration: const Duration(seconds: 5),
        );
        return;
      }
    }

    final res = await _authService.returnToStandby(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    if (!_isApiSuccess(res)) {
      AppNotifier.error('Gagal Return', res?['message'] ?? 'Gagal return to standby');
      return;
    }

    checkInStatus.value = 'standby';
    AppNotifier.success('Berhasil', res?['message'] ?? 'Kamu sudah kembali ke standby');
    await refreshWithDelay();
  }

  Future<void> _doCheckOut() async {
    final confirm = await AppNotifier.confirmDialog(
      title: 'Konfirmasi Check-Out',
      message: 'Apakah kamu yakin ingin mengakhiri sesi check-in ini?',
      confirmText: 'Ya, Check-Out',
      type: AppNoticeType.error,
    );
    if (!confirm) return;

    final res = await _authService.checkout();
    if (!_isApiSuccess(res)) {
      AppNotifier.error('Gagal Check-Out', res?['message'] ?? res?['error'] ?? 'Check-out ditolak server');
      return;
    }

    checkInStatus.value = 'offline';
    AppNotifier.info('Check-Out Berhasil', res?['message'] ?? 'Sesi telah diakhiri');
    await refreshWithDelay();
  }

  bool _isApiSuccess(Map<String, dynamic>? res) {
    if (res == null) return false;
    // API baru: error == true atau statusCode 4xx/5xx = gagal
    if (res['error'] == true) return false;
    final statusCode = res['statusCode'] as int?;
    if (statusCode != null && statusCode >= 400) return false;
    // API lama (fallback)
    final code = res['response_code']?.toString();
    if (code != null && code.startsWith('4')) return false;
    if (res['success'] == false) return false;
    return true;
  }

  Future<void> _handleSnapPaymentResult(dynamic result) async {
    if (result == 'success') {
      await refreshSessionStatus();
      AppNotifier.success(
        'Pembayaran Berhasil',
        'Sesi kerja kamu sudah aktif.',
        duration: const Duration(seconds: 5),
      );
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
      await refreshSessionStatus();
      return;
    }
    if (result == 'closed') {
      AppNotifier.warning(
        'Pembayaran Dibatalkan',
        'Kamu menutup halaman pembayaran sebelum selesai.',
      );
      await refreshSessionStatus();
    }
  }

  Future<void> logout() => AppNotifier.confirmAndLogout();

  Future<bool> requestBiometricForCheckIn() async {
    try {
      final bool authenticated = await biometricService.authenticate(
        reason: 'Konfirmasi identitas untuk check-in',
      );
      if (!authenticated) {
        AppNotifier.warning(
          'Verifikasi Gagal',
          'Autentikasi biometrik dibutuhkan untuk check-in.',
          duration: const Duration(seconds: 4),
        );
      }
      return authenticated;
    } catch (e) {
      AppNotifier.error(
        'Biometrik Error',
        'Gagal memverifikasi identitas: ${e.toString().split('\n').first}',
        duration: const Duration(seconds: 5),
      );
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
