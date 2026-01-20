import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = AuthService();

  final userName = ''.obs;
  final userEmail = ''.obs;

  final isCheckedIn = false.obs;
  final statusText = 'Off'.obs;
  final isProcessing = false.obs;

  final snapToken = ''.obs;
  final paymentStatus = 'none'.obs;

  Timer? _statusPollingTimer;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      userName.value = args['name']?.toString() ?? 'Admin';
      userEmail.value = args['email']?.toString() ?? 'admin@cico.com';
    }
    loadCheckInStatus();
  }

  @override
  void onClose() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    super.onClose();
  }

  Future<void> loadCheckInStatus() async {
    final session = await _authService.getCheckInSession();
    if (session == null || session['status'] != 'success') {
      _resetToIdle();
      return;
    }

    print('SESSION FULL: $session');
    final checkinData =
        session['data']?['checkin_session'] as Map<String, dynamic>?;
    if (checkinData == null) {
      _resetToIdle();
      return;
    }

    final wasCheckedIn = isCheckedIn.value;
    final serverStatus =
        (checkinData['status'] as String?)?.toLowerCase() ?? 'none';
    final hasStartTime = checkinData['start_time'] != null;

    isCheckedIn.value =
        hasStartTime ||
        serverStatus == 'active' ||
        serverStatus == 'in_progress';

    // Infer payment status
    String newPayment = 'none';
    if (serverStatus == 'waiting_for_payment') {
      newPayment = 'pending';
    } else if (isCheckedIn.value) {
      newPayment = 'paid';
    }

    if (paymentStatus.value == 'pending' && newPayment != 'pending') {
      print('pending lokal masih menunggu konfirmasi');
    } else {
      paymentStatus.value = newPayment;
    }

    // Token handling
    final serverToken =
        (checkinData['snap_token'] ?? checkinData['token'] ?? '') as String;
    if (paymentStatus.value == 'pending' && serverToken.isNotEmpty) {
      if (snapToken.value.isEmpty) {
        snapToken.value = serverToken;
        print(
          '→ Snap token baru diterima: ${snapToken.value.substring(0, 10)}...',
        );
      }
    } else {
      snapToken.value = '';
    }

    // Update UI text
    if (paymentStatus.value == 'pending') {
      statusText.value = 'Menunggu Pembayaran';
    } else if (isCheckedIn.value) {
      statusText.value = 'Aktif';
    } else {
      statusText.value = 'Off';
    }

    // Notifikasi transisi ke aktif
    if (!wasCheckedIn && isCheckedIn.value) {
      Get.snackbar(
        'Pembayaran Berhasil!',
        'Sesi aktif sampai ${checkinData['end_time'] ?? 'waktu tertentu'}',
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    }
    print(
      '→ Parsed → checkedIn: ${isCheckedIn.value} | '
      'payment: ${paymentStatus.value} | '
      'token: ${snapToken.value.isNotEmpty ? "ada" : "kosong"} | '
      'statusText: ${statusText.value} | serverStatus: $serverStatus',
    );
  }

  void _resetToIdle() {
    isCheckedIn.value = false;
    statusText.value = 'Off';
    paymentStatus.value = 'none';
    snapToken.value = '';
  }

  Future<void> refreshSessionStatus() async {
    try {
      await loadCheckInStatus();
    } catch (e) {
      print('Refresh status error: $e');
    }
  }

  Future<void> refreshWithDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
    await refreshSessionStatus();
  }

  void _startPollingCheckInSession() {
    _statusPollingTimer?.cancel();

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 6), (
      timer,
    ) async {
      if (paymentStatus.value != 'pending') {
        timer.cancel();
        return;
      }

      await loadCheckInStatus();
      if (paymentStatus.value != 'pending' || isCheckedIn.value) {
        timer.cancel();
      }
    });
  }

  Future<void> toggleCheckInOut() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      await refreshSessionStatus();
      final bool shouldCheckOut = isCheckedIn.value;
      if (!shouldCheckOut) {
        // CHECK-IN
        final res = await _authService.checkIn();
        print('CHECK-IN RESPONSE: $res');

        if (!_isApiSuccess(res)) {
          final msg = res?['message'] ?? res?['error'] ?? 'Gagal check-in';
          print('→ CHECK-IN GAGAL: $msg');
          Get.snackbar('Gagal Check-In', msg, backgroundColor: Colors.red[700]);
          return;
        }

        await refreshSessionStatus();
        if (paymentStatus.value == 'pending') {
          _startPollingCheckInSession();
          Get.snackbar(
            'Sukses',
            'Silakan bayar melalui QRIS',
            backgroundColor: Colors.green[700],
          );
        } else if (isCheckedIn.value) {
          Get.snackbar(
            'Check-In Berhasil',
            'Sesi langsung aktif',
            backgroundColor: Colors.green[800],
          );
        } else {
          await retryPay();
        }
      } else {
        // CHECK-OUT
        final res = await _authService.checkout();
        print('CHECK-OUT RESPONSE FULL: $res');

        if (!_isApiSuccess(res)) {
          final msg =
              res?['message'] ?? res?['error'] ?? 'Check-out ditolak server';
          Get.snackbar(
            'Gagal Check-Out',
            msg,
            backgroundColor: Colors.red[700],
          );
          return;
        }

        isCheckedIn.value = false;
        paymentStatus.value = 'none';
        snapToken.value = '';
        statusText.value = 'Off';
        Get.snackbar(
          'Check-Out Berhasil',
          res?['message'] ?? 'Sesi telah diakhiri',
          backgroundColor: Colors.amber[700],
          colorText: Colors.white,
        );
        await refreshWithDelay();
        if (isCheckedIn.value) {
          Get.snackbar(
            'Peringatan',
            'Check-out tampak berhasil tapi sesi masih aktif di server.\nTunggu 10-30 detik atau cek backend.',
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 7),
          );
        }
      }
    } catch (e, stack) {
      print('→ EXCEPTION di toggleCheckInOut: $e');
      print('Stack: $stack');
      Get.snackbar(
        'Error',
        'Gagal proses: $e',
        backgroundColor: Colors.red[900],
      );
    } finally {
      isProcessing.value = false;
      await refreshSessionStatus();
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

    if (isSuccessPattern && hasErrorIndication) {
      //
    }

    return false;
  }

  Future<void> retryPay() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    try {
      final res = await _authService.pay();
      await _handlePayResponse(res);
    } catch (e) {
      print('Retry pay error: $e');
      Get.snackbar('Error', 'Gagal membuat pembayaran: $e');
    } finally {
      isProcessing.value = false;
      await refreshSessionStatus();
    }
  }

  Future<void> _handlePayResponse(Map<String, dynamic>? res) async {
    if (res == null) {
      Get.snackbar('Error', 'Tidak ada respon server');
      return;
    }

    if (_isApiSuccess(res)) {
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final token =
          (data['snap_token'] ?? data['token'] ?? data['qris_token'] ?? '')
              as String;

      snapToken.value = token;

      if (token.isNotEmpty) {
        paymentStatus.value = 'pending';
        Get.snackbar(
          'Sukses',
          'QRIS siap dibayar',
          backgroundColor: Colors.green,
        );
        _startPollingCheckInSession();
      } else {
        Get.snackbar('Peringatan', 'Token pembayaran kosong');
      }
    } else {
      final msg = res['message'] ?? 'Gagal membuat pembayaran';
      print('Pay gagal: $msg');
      Get.snackbar('Gagal', msg, backgroundColor: Colors.red[800]);
    }
  }

  Future<void> logout() async {
    try {
      await _authService.performLogout();
    } finally {
      userName.value = '';
      Get.offAllNamed('/login');
    }
  }
}
