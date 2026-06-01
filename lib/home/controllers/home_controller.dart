import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cico_project/auth/services/biometric_service.dart';
import 'package:cico_project/core/utils/auth_helper.dart';
import 'package:cico_project/core/utils/date_utils.dart' as tz;
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:cico_project/home/views/snap_payment_page.dart';
import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Aksi driver yang sedang berjalan — dipakai view untuk spinner per-button.
enum DriverAction { none, checkin, retry, checkout, returnStandby }

class HomeController extends GetxController with WidgetsBindingObserver {
  /// Delay setelah aksi berhasil sebelum refresh status dari server.
  /// Memberi waktu backend memproses sebelum response-nya diambil.
  static const _kAfterActionDelay = Duration(milliseconds: 800);
  final AuthService _authService = Get.find<AuthService>();

  final isInitializing = true.obs;
  final isRefreshing = false.obs;
  final userName = ''.obs;
  final vehicleNumber = ''.obs;

  final startTime = ''.obs;
  final endTime = ''.obs;

  final checkInStatus = ''.obs;

  final activeAction = DriverAction.none.obs;

  final remainingMinutes = Rxn<int>();

  final _biometricService = Get.find<BiometricService>();  // private

  final _currentPosition = Rxn<Position>();                // private — view pakai currentAddress
  final currentAddress = ''.obs;

  Timer? _statusPollingTimer;
  Timer? _countdownTimer;
  bool _isLoadingStatus = false;   // guard concurrent loadCheckInStatus calls
  DateTime? _locationTimestamp;    // untuk expiry cache posisi GPS

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initDashboard();
    _fetchCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      manualRefresh();
      // Refresh lokasi hanya jika cache sudah lebih dari 10 menit atau belum pernah dapat
      final isLocationStale = _locationTimestamp == null ||
          DateTime.now().difference(_locationTimestamp!) > const Duration(minutes: 10);
      if (isLocationStale) _fetchCurrentLocation();
    }
  }

  Future<void> _initDashboard() async {
    isInitializing.value = true;
    await _loadCheckInStatus();
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

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppNotifier.warning('loc_label'.tr, 'loc_disabled'.tr);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppNotifier.warning('loc_label'.tr, 'loc_denied'.tr);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        final openSettings = await AppNotifier.confirmDialog(
          title: 'loc_blocked_title'.tr,
          message: 'loc_blocked_msg'.tr,
          confirmText: 'loc_open_settings'.tr,
          cancelText: 'loc_later'.tr,
          type: AppNoticeType.warning,
        );
        if (openSettings) await Geolocator.openAppSettings();
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition.value = pos;
      _locationTimestamp = DateTime.now();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        currentAddress.value = parts.join(', ');
      } else {
        currentAddress.value = 'loc_not_found'.tr;
      }
    } catch (e) {
      AppNotifier.error('loc_label'.tr, 'loc_error'.tr);
      currentAddress.value = 'loc_error_address'.tr;
    }
  }

  Future<void> _loadCheckInStatus() async {
    if (_isLoadingStatus) return; // cegah concurrent calls
    _isLoadingStatus = true;
    try {
      final previousStatus = checkInStatus.value;
      final dashboard = await _authService.getDashboard();
      if (dashboard == null) {
        // Jika token tidak ada, interceptor sudah handle logout & redirect —
        // jangan tampilkan warning yang membingungkan sebelum redirect ke login.
        if (_authService.getToken() == null) return;

        // Pertahankan status terakhir jika network error — reset hanya saat first launch
        if (checkInStatus.value.isEmpty) {
          _resetToIdle();
        } else {
          AppNotifier.warning('connection_label'.tr, 'failed_load_status'.tr);
        }
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

      // Countdown lokal setiap menit jika ada sisa waktu
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
          'payment_active_title'.tr,
          'payment_active_msg'.tr,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      _isLoadingStatus = false;
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
      await _loadCheckInStatus();
    } catch (e) {
      // Tidak notifikasi agar tidak ganggu UX — error kritis ditangani interceptor
      if (kDebugMode) debugPrint('[HomeController] refreshSessionStatus error: $e');
    }
  }

  Future<void> refreshWithDelay() async {
    await Future.delayed(_kAfterActionDelay);
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
    if (activeAction.value != DriverAction.none) return;
    final status = checkInStatus.value;

    // Set aksi spesifik agar view bisa menampilkan spinner di tombol yang tepat
    if (status == 'pending_payment') {
      activeAction.value = DriverAction.retry;
    } else if (status == 'standby') {
      activeAction.value = DriverAction.checkout;
    } else {
      activeAction.value = DriverAction.checkin;
    }

    try {
      if (status == 'pending_payment') {
        await _doRetryPayment();
        return;
      }
      if (status == 'standby') {
        await _doCheckOut();
        return;
      }
      await _doCheckIn();
    } catch (e) {
      AppNotifier.error('error_processing_title'.tr, 'error_processing_msg'.tr);
    } finally {
      activeAction.value = DriverAction.none;
    }
  }

  /// Ambil posisi saat ini.
  /// Cache valid selama [maxAge] (default 10 menit). Return null + tampilkan error jika gagal.
  Future<Position?> _ensureLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
    Duration maxAge = const Duration(minutes: 10),
  }) async {
    final cached = _currentPosition.value;
    if (cached != null && _locationTimestamp != null) {
      if (DateTime.now().difference(_locationTimestamp!) < maxAge) return cached;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      ).timeout(timeout);
      _currentPosition.value = pos;
      _locationTimestamp = DateTime.now();
      return pos;
    } catch (_) {
      AppNotifier.error(
        'loc_unavailable_title'.tr,
        'loc_unavailable_msg'.tr,
        duration: const Duration(seconds: 5),
      );
      return null;
    }
  }

  /// Ekstrak snapRedirectUrl dari response check-in.
  /// Format baru: { success: true, data: { payment: { snapRedirectUrl } } }
  String _extractRedirectUrl(Map<String, dynamic>? res) {
    final data = res?['data'] as Map<String, dynamic>?;
    final payment = data?['payment'] as Map<String, dynamic>?;
    return payment?['snapRedirectUrl'] as String? ?? '';
  }

  Future<void> _doCheckIn() async {
    // 1. Biometric wajib
    final bool authenticated = await _requestBiometricForCheckIn();
    if (!authenticated) return;

    // 2. Lokasi wajib
    final pos = await _ensureLocation();
    if (pos == null) return;

    // 3. Request check-in
    final res = await _authService.checkIn(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!AuthService.isSuccess(res)) {
      AppNotifier.error(
        'checkin_failed_title'.tr,
        AuthService.extractMessage(res?['message'], fallback: 'checkin_failed_title'.tr),
      );
      await refreshSessionStatus();
      return;
    }

    // 4. Buka payment jika ada redirectUrl, atau refresh status langsung
    final redirectUrl = _extractRedirectUrl(res);
    if (redirectUrl.isNotEmpty) {
      // Langsung buka payment — tidak perlu refresh dulu karena status
      // sudah pasti 'pending_payment' setelah check-in berhasil.
      // Refresh dilakukan di _handleSnapPaymentResult setelah payment selesai.
      final result = await Get.to(() => SnapPaymentPage(redirectUrl: redirectUrl));
      await _handleSnapPaymentResult(result);
    } else {
      await refreshSessionStatus();
      if (checkInStatus.value == 'on_duty' || checkInStatus.value == 'standby') {
        AppNotifier.success('checkin_success_title'.tr, 'checkin_success_msg'.tr);
      }
    }
  }

  // Retry payment: panggil /driver/checkin lagi untuk dapat redirect_url baru
  Future<void> _doRetryPayment() async {
    final pos = await _ensureLocation(
      accuracy: LocationAccuracy.low,
      timeout: const Duration(seconds: 5),
    );
    if (pos == null) return;

    final res = await _authService.checkIn(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    if (!AuthService.isSuccess(res)) {
      AppNotifier.error(
        'payment_retry_label'.tr,
        AuthService.extractMessage(res?['message'], fallback: 'payment_retry_label'.tr),
      );
      return;
    }

    final redirectUrl = _extractRedirectUrl(res);
    if (redirectUrl.isEmpty) {
      AppNotifier.warning('payment_retry_label'.tr, 'payment_no_url'.tr);
      return;
    }

    final result = await Get.to(() => SnapPaymentPage(redirectUrl: redirectUrl));
    await _handleSnapPaymentResult(result);
  }

  /// Dipanggil dari SwipeButton Return saat status on_duty
  Future<void> returnToStandby() async {
    if (activeAction.value != DriverAction.none) return;
    activeAction.value = DriverAction.returnStandby;
    try {
      await _doReturnToStandby();
    } catch (e) {
      AppNotifier.error('Terjadi Kesalahan', 'Gagal memproses permintaan.');
    } finally {
      activeAction.value = DriverAction.none;
    }
  }

  /// Dipanggil dari SwipeButton Check-Out saat status on_duty
  Future<void> checkOutFromDuty() async {
    if (activeAction.value != DriverAction.none) return;
    activeAction.value = DriverAction.checkout;
    try {
      await _doCheckOut();
    } catch (e) {
      AppNotifier.error('error_processing_title'.tr, 'error_processing_msg'.tr);
    } finally {
      activeAction.value = DriverAction.none;
    }
  }

  Future<void> _doReturnToStandby() async {
    final pos = await _ensureLocation();
    if (pos == null) return;

    final res = await _authService.returnToStandby(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    if (!AuthService.isSuccess(res)) {
      AppNotifier.error('return_failed_title'.tr,
          AuthService.extractMessage(res?['message'], fallback: 'return_failed_title'.tr));
      return;
    }

    checkInStatus.value = 'standby';
    AppNotifier.success('return_success_title'.tr,
        AuthService.extractMessage(res?['message'], fallback: 'return_success_title'.tr));
    await refreshWithDelay();
  }

  Future<void> _doCheckOut() async {
    final confirm = await AppNotifier.confirmDialog(
      title: 'checkout_confirm_title'.tr,
      message: 'checkout_confirm_msg'.tr,
      confirmText: 'checkout_confirm_btn'.tr,
      type: AppNoticeType.error,
    );
    if (!confirm) return;

    final res = await _authService.checkout();
    if (!AuthService.isSuccess(res)) {
      AppNotifier.error('checkout_failed_title'.tr,
          AuthService.extractMessage(res?['message'], fallback: 'checkout_failed_title'.tr));
      return;
    }

    checkInStatus.value = 'offline';
    AppNotifier.info('checkout_success_title'.tr,
        AuthService.extractMessage(res?['message'], fallback: 'checkout_success_title'.tr));
    await refreshWithDelay();
  }

  Future<void> _handleSnapPaymentResult(dynamic result) async {
    switch (result) {
      case null: // user tekan back tanpa navigation result (Android back button)
        await refreshSessionStatus();
      case 'success':
        await refreshSessionStatus();
        AppNotifier.success(
          'payment_active_title'.tr,
          'payment_active_msg'.tr,
          duration: const Duration(seconds: 5),
        );
      case 'pending':
        AppNotifier.warning(
          'payment_pending_title'.tr,
          'payment_pending_msg'.tr,
        );
      case 'failed':
        AppNotifier.error(
          'payment_failed_title'.tr,
          'payment_failed_msg'.tr,
        );
        await refreshSessionStatus();
      case 'closed':
        AppNotifier.warning(
          'payment_cancelled_title'.tr,
          'payment_cancelled_msg'.tr,
        );
        await refreshSessionStatus();
    }
  }

  Future<void> logout() => AuthHelper.confirmAndLogout();

  Future<bool> _requestBiometricForCheckIn() async {
    try {
      final bool authenticated = await _biometricService.authenticate(
        reason: 'biometric_reason'.tr,
      );
      if (!authenticated) {
        AppNotifier.warning(
          'verify_failed_title'.tr,
          'verify_failed_msg'.tr,
          duration: const Duration(seconds: 4),
        );
      }
      return authenticated;
    } catch (e) {
      AppNotifier.error(
        'biometric_error_title'.tr,
        'Gagal memverifikasi identitas: ${e.toString().split('\n').first}',
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  Future<void> manualRefresh() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    _locationTimestamp = null; // force refresh GPS on manual refresh
    try {
      await Future.wait([
        _loadCheckInStatus(),
        _fetchCurrentLocation(),
      ]);
    } catch (e) {
      AppNotifier.error(
        'refresh_failed_title'.tr,
        'refresh_failed_msg'.tr,
      );
    } finally {
      isRefreshing.value = false;
    }
  }
}
