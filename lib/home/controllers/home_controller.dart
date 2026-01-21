import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';

class HomeController extends GetxController {
  final AuthService _authService = AuthService();

  final userName = ''.obs;
  final userEmail = ''.obs;

  final checkInStatus = ''.obs;
  final isCheckedIn = false.obs;
  final statusText = 'Off'.obs;
  final isProcessing = false.obs;

  final snapToken = ''.obs;

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
  }

  @override
  void onClose() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    super.onClose();
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
    if (checkinData == null) {
      print('→ Tidak ada checkin_session di response');
      _resetToIdle();
      return;
    }
    final serverStatus =
        (checkinData['status'] as String?)?.toLowerCase() ?? 'none';
    checkInStatus.value = serverStatus;

    print("checkInStatus: ${checkInStatus.value}");

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
      Get.snackbar(
        'Pembayaran Berhasil!',
        'Sesi aktif sampai ${checkinData['end_time'] ?? 'waktu tertentu'}',
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _resetToIdle() {
    isCheckedIn.value = false;
    statusText.value = 'Off';
    checkInStatus.value = 'expired';
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
    isProcessing.value = true;
    try {
      await refreshSessionStatus();
      if (checkInStatus.value == 'waiting_for_payment') {
        print('→ Status sudah pending setelah refresh');
        Get.snackbar(
          'Sukses',
          'Silakan bayar melalui QRIS',
          backgroundColor: Colors.green[700],
        );
        if (snapToken.value.isEmpty) {
          await retryPay();
        } else {
          print('→ Token sudah ada, skip retryPay');
        }
        return;
      }
      final bool shouldCheckOut = isCheckedIn.value;
      if (!shouldCheckOut) {
        final res = await _authService.checkIn();
        if (!_isApiSuccess(res)) {
          final msg = res?['message'] ?? res?['error'] ?? 'Gagal check-in';

          // Handle kasus pending existing
          if (msg.toLowerCase().contains('waiting_for_payment') ||
              msg.toLowerCase().contains('active')) {
            if (snapToken.value.isEmpty) {
              await retryPay();
            }
          } else {
            Get.snackbar(
              'Gagal Check-In',
              msg,
              backgroundColor: Colors.red[700],
            );
          }
          return;
        }
        await refreshSessionStatus();
        if (checkInStatus.value == 'waiting_for_payment') {
          Get.snackbar(
            'Sukses',
            'Silakan bayar melalui QRIS',
            backgroundColor: Colors.green[700],
          );
          if (snapToken.value.isEmpty) {
            print("retryPay dipanggil di toggle");
            await retryPay();
          }
        } else if (isCheckedIn.value) {
          Get.snackbar(
            'Check-In Berhasil',
            'Sesi langsung aktif',
            backgroundColor: Colors.green[800],
          );
        }
      } else {
        // CHECK-OUT
        final res = await _authService.checkout();
        if (!_isApiSuccess(res)) {
          final msg =
              res?['message'] ?? res?['error'] ?? 'Check-out ditolak server';
          print('→ CHECK-OUT GAGAL: $msg');
          print('Full response: $res');
          Get.snackbar(
            'Gagal Check-Out',
            msg,
            backgroundColor: Colors.red[700],
          );
          return;
        }
        // Update
        isCheckedIn.value = false;
        checkInStatus.value = 'expired';
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
      print('EXCEPTION di toggleCheckInOut: $e');
      print('Stack: $stack');
      Get.snackbar(
        'Error',
        'Gagal proses: $e',
        backgroundColor: Colors.red[900],
      );
    } finally {
      isProcessing.value = false;
      if (!(checkInStatus.value == 'waiting_for_payment' &&
          snapToken.value.isNotEmpty)) {
        await refreshSessionStatus();
      }
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
      Get.snackbar('Error', 'Gagal membuat pembayaran: $e');
    } finally {
      isProcessing.value = false;
      // await refreshSessionStatus();
    }
  }

  Future<void> _handlePayResponse(Map<String, dynamic>? res) async {
    if (res == null) {
      Get.snackbar('Error', 'Tidak ada respon server');
      return;
    }

    if (_isApiSuccess(res)) {
      final data = res['data'] as Map<String, dynamic>? ?? res;
      final token = (data['snap_token'] ?? data['token']) as String;
      if (token.isNotEmpty) {
        snapToken.value = token;
        checkInStatus.value = 'waiting_for_payment';
        print('Token berhasil: $token');
        Get.snackbar(
          'Sukses',
          'QRIS siap dibayar',
          backgroundColor: Colors.green,
        );
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
