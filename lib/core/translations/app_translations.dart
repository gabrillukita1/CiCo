import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'id_ID': _id,
        'en_US': _en,
      };

  static const Map<String, String> _id = {
    // ── Login ────────────────────────────────────────────────────────────────
    'login_hero_subtitle':
        'Clock in, clock out, dan pantau setiap shift dalam satu ketukan.',
    'sign_in_title': 'Masuk',
    'sign_in_subtitle': 'Gunakan akun driver yang sudah ditetapkan.',
    'email_label': 'EMAIL',
    'password_label': 'KATA SANDI',
    'sign_in_btn': 'Masuk',

    // ── Navigation ───────────────────────────────────────────────────────────
    'nav_home': 'Beranda',
    'nav_history': 'Riwayat',
    'nav_profile': 'Profil',

    // ── Home ─────────────────────────────────────────────────────────────────
    'loading_dashboard': 'Memuat dashboard...',
    'welcome_back': 'Selamat datang',
    'location_label': 'LOKASI',
    'getting_location': 'Mengambil lokasi...',
    'hrs_min_label': 'JAM : MENIT',

    // Stage tag (status pill)
    'stage_tag_offline': 'OFFLINE',
    'stage_tag_standby': 'STANDBY',
    'stage_tag_on_duty': 'ON DUTY',
    'stage_tag_pending': 'PENDING PAYMENT',

    // Stage subtitle
    'stage_sub_offline': 'Mulai shift untuk online',
    'stage_sub_standby': 'Menunggu dispatch',
    'stage_sub_on_duty': 'Kamu live — berkendara aman',
    'stage_sub_pending': 'Selesaikan pembayaran untuk aktif',

    // Stage kicker (label atas angka besar)
    'stage_kicker_offline': 'BELUM CLOCK IN',
    'stage_kicker_time': 'SISA WAKTU',
    'stage_kicker_pending': 'JUMLAH BAYAR',

    // Stage footer label
    'footer_method': 'METODE',
    'footer_checkin_time': 'CHECK-IN',
    'footer_due': 'JATUH TEMPO',
    'footer_expires': 'KADALUARSA',

    // Swipe button labels
    'swipe_checkin': 'GESER UNTUK CHECK-IN',
    'swipe_checkout': 'GESER UNTUK CHECK-OUT',
    'swipe_pay': 'GESER UNTUK BAYAR',
    'swipe_return': 'GESER UNTUK RETURN',
    'swipe_busy_returning': 'Returning...',
    'swipe_busy_checkout': 'Check-Out...',
    'swipe_busy_wait': 'Harap tunggu...',

    // ── History ───────────────────────────────────────────────────────────────
    'history_title': 'Riwayat',
    'filter_all': 'Semua',
    'filter_today': 'Hari Ini',
    'filter_week': 'Minggu Ini',
    'filter_month': 'Bulan Ini',
    'filter_custom': 'Kustom',
    'no_sessions': 'Belum ada sesi',
    'checkin_label': 'Check-in',
    'checkout_label': 'Check-out',
    'payment_section': 'PEMBAYARAN',
    'pay_status_paid': 'Lunas',
    'pay_status_pending': 'Pending',
    'pay_status_expired': 'Kadaluarsa',
    'pay_status_failed': 'Gagal',
    'dispatch_section': 'Dispatch',
    'dispatch_unit': 'dispatch',
    'dispatch_by_label': 'Dispatch oleh',
    'dispatch_at_label': 'Dispatch pukul',

    // ── Profile ───────────────────────────────────────────────────────────────
    'profile_title': 'Profil',
    'failed_load_profile': 'Gagal memuat profil',
    'try_again': 'Coba Lagi',
    'driver_id_label': 'DRIVER ID',
    'plate_number_label': 'NOMOR PLAT',
    'account_section': 'Akun',
    'vehicle_section': 'Kendaraan',
    'email_row_label': 'EMAIL',
    'phone_row_label': 'TELEPON',
    'plate_row_label': 'NOMOR PLAT',
    'vehicle_type_label': 'TIPE KENDARAAN',
    'logout_btn': 'Keluar',
    'language_section': 'Bahasa',
    'code_copied_title': 'Kode Disalin',
    'code_copied_msg': 'Kode driver berhasil disalin ke clipboard.',
    'valid_label': 'VALID',

    // ── Status Helper ─────────────────────────────────────────────────────────
    'status_on_duty': 'On Duty',
    'status_standby': 'Standby',
    'status_pending_payment': 'Pending Payment',
    'status_offline': 'Offline',
    'status_active': 'Aktif',
    'status_completed': 'Selesai',
    'status_expired': 'Kadaluarsa',

    // ── Location (HomeController) ─────────────────────────────────────────────
    'loc_label': 'Lokasi',
    'loc_disabled': 'Layanan lokasi tidak aktif',
    'loc_denied': 'Izin lokasi ditolak',
    'loc_blocked_title': 'Izin Lokasi Diblokir',
    'loc_blocked_msg':
        'Izin lokasi diblokir permanen. Buka pengaturan untuk mengaktifkannya.',
    'loc_open_settings': 'Buka Pengaturan',
    'loc_later': 'Nanti',
    'loc_error': 'Gagal mengambil lokasi. Coba lagi.',
    'loc_not_found': 'Alamat tidak ditemukan',
    'loc_error_address': 'Gagal mendapatkan alamat',
    'loc_unavailable_title': 'Lokasi Tidak Tersedia',
    'loc_unavailable_msg':
        'Aktifkan GPS dan pastikan izin lokasi sudah diberikan, lalu coba lagi.',

    // ── Connectivity ─────────────────────────────────────────────────────────
    'connection_label': 'Koneksi',
    'failed_load_status': 'Gagal memuat status. Menampilkan data terakhir.',

    // ── Payment ───────────────────────────────────────────────────────────────
    'payment_active_title': 'Pembayaran Berhasil!',
    'payment_active_msg': 'Sesi kerja Anda sudah aktif.',
    'payment_pending_title': 'Pembayaran Pending',
    'payment_pending_msg':
        'Transaksi masih diproses. Cek kembali beberapa saat lagi.',
    'payment_failed_title': 'Pembayaran Gagal',
    'payment_failed_msg': 'Transaksi tidak berhasil. Silakan coba lagi.',
    'payment_cancelled_title': 'Pembayaran Dibatalkan',
    'payment_cancelled_msg':
        'Kamu menutup halaman pembayaran sebelum selesai.',
    'payment_retry_label': 'Pembayaran',
    'payment_no_url': 'URL pembayaran tidak ditemukan.',

    // ── Dispatch ──────────────────────────────────────────────────────────────
    'dispatched_title': 'Kamu Sudah Dispatched!',
    'dispatched_msg': 'Kamu sekarang sedang bertugas. Berkendara aman.',

    // ── Check-in / Check-out ──────────────────────────────────────────────────
    'checkin_success_title': 'Check-In Berhasil',
    'checkin_success_msg': 'Sesi langsung aktif',
    'checkin_failed_title': 'Gagal Check-In',
    'checkout_success_title': 'Check-Out Berhasil',
    'checkout_failed_title': 'Gagal Check-Out',
    'checkout_confirm_title': 'Konfirmasi Check-Out',
    'checkout_confirm_msg':
        'Apakah kamu yakin ingin mengakhiri sesi check-in ini?',
    'checkout_confirm_btn': 'Ya, Check-Out',
    'return_success_title': 'Kembali ke Standby',
    'return_failed_title': 'Gagal Return',
    'error_processing_title': 'Terjadi Kesalahan',
    'error_processing_msg': 'Gagal memproses permintaan.',

    // ── Biometric / Auth ──────────────────────────────────────────────────────
    'verify_failed_title': 'Verifikasi Gagal',
    'verify_failed_msg': 'Autentikasi biometrik dibutuhkan untuk check-in.',
    'verify_error_title': 'Gagal Verifikasi',
    'verify_error_default': 'Verifikasi gagal, coba lagi.',
    'biometric_error_title': 'Biometrik Error',
    'biometric_reason': 'Konfirmasi identitas untuk check-in',
    'lockscreen_title': 'Kunci Layar Diperlukan',
    'lockscreen_msg':
        'HP ini belum memiliki kunci layar (PIN, pola, atau sidik jari).\n\n'
            'Buka Pengaturan → Keamanan → Kunci Layar, lalu atur PIN atau biometrik terlebih dahulu.',
    'lockscreen_btn': 'Mengerti',

    // ── Logout ────────────────────────────────────────────────────────────────
    'logout_confirm_title': 'Konfirmasi Logout',
    'logout_confirm_msg': 'Apakah kamu yakin ingin logout dari aplikasi?',
    'logout_confirm_btn': 'Ya, Logout',

    // ── Login validation ──────────────────────────────────────────────────────
    'validation_label': 'Validasi',
    'validation_empty': 'Email dan password harus diisi',
    'validation_email': 'Format email tidak valid',

    // ── Misc ──────────────────────────────────────────────────────────────────
    'refresh_failed_title': 'Refresh Gagal',
    'refresh_failed_msg': 'Tidak dapat memperbarui status.',
  };

  static const Map<String, String> _en = {
    // ── Login ────────────────────────────────────────────────────────────────
    'login_hero_subtitle':
        'Clock in, clock out, and track every shift in one tap.',
    'sign_in_title': 'Sign In',
    'sign_in_subtitle': 'Use your assigned driver account.',
    'email_label': 'EMAIL',
    'password_label': 'PASSWORD',
    'sign_in_btn': 'Sign In',

    // ── Navigation ───────────────────────────────────────────────────────────
    'nav_home': 'Home',
    'nav_history': 'History',
    'nav_profile': 'Profile',

    // ── Home ─────────────────────────────────────────────────────────────────
    'loading_dashboard': 'Loading dashboard...',
    'welcome_back': 'Welcome back',
    'location_label': 'LOCATION',
    'getting_location': 'Getting location...',
    'hrs_min_label': 'HRS : MIN',

    // Stage tag (status pill)
    'stage_tag_offline': 'OFFLINE',
    'stage_tag_standby': 'STANDBY',
    'stage_tag_on_duty': 'ON DUTY',
    'stage_tag_pending': 'PENDING PAYMENT',

    // Stage subtitle
    'stage_sub_offline': 'Start your shift to go online',
    'stage_sub_standby': 'Waiting for dispatch',
    'stage_sub_on_duty': "You're live — drive safe",
    'stage_sub_pending': 'Complete payment to activate',

    // Stage kicker (label above big number)
    'stage_kicker_offline': 'NOT CLOCKED IN',
    'stage_kicker_time': 'REMAINING TIME',
    'stage_kicker_pending': 'AMOUNT DUE',

    // Stage footer label
    'footer_method': 'METHOD',
    'footer_checkin_time': 'CHECK-IN',
    'footer_due': 'DUE',
    'footer_expires': 'EXPIRES',

    // Swipe button labels
    'swipe_checkin': 'SWIPE TO CHECK-IN',
    'swipe_checkout': 'SWIPE TO CHECK-OUT',
    'swipe_pay': 'SWIPE TO PAY',
    'swipe_return': 'SWIPE TO RETURN',
    'swipe_busy_returning': 'Returning...',
    'swipe_busy_checkout': 'Checking Out...',
    'swipe_busy_wait': 'Please wait...',

    // ── History ───────────────────────────────────────────────────────────────
    'history_title': 'History',
    'filter_all': 'All',
    'filter_today': 'Today',
    'filter_week': 'This Week',
    'filter_month': 'This Month',
    'filter_custom': 'Custom',
    'no_sessions': 'No sessions yet',
    'checkin_label': 'Check-in',
    'checkout_label': 'Check-out',
    'payment_section': 'PAYMENT',
    'pay_status_paid': 'Paid',
    'pay_status_pending': 'Pending',
    'pay_status_expired': 'Expired',
    'pay_status_failed': 'Failed',
    'dispatch_section': 'Dispatch',
    'dispatch_unit': 'dispatch',
    'dispatch_by_label': 'Dispatch by',
    'dispatch_at_label': 'Dispatch at',

    // ── Profile ───────────────────────────────────────────────────────────────
    'profile_title': 'Profile',
    'failed_load_profile': 'Failed to load profile',
    'try_again': 'Try Again',
    'driver_id_label': 'DRIVER ID',
    'plate_number_label': 'PLATE NUMBER',
    'account_section': 'Account',
    'vehicle_section': 'Vehicle',
    'email_row_label': 'EMAIL',
    'phone_row_label': 'PHONE',
    'plate_row_label': 'PLATE NUMBER',
    'vehicle_type_label': 'VEHICLE TYPE',
    'logout_btn': 'Log Out',
    'language_section': 'Language',
    'code_copied_title': 'Code Copied',
    'code_copied_msg': 'Driver code copied to clipboard.',
    'valid_label': 'VALID',

    // ── Status Helper ─────────────────────────────────────────────────────────
    'status_on_duty': 'On Duty',
    'status_standby': 'Standby',
    'status_pending_payment': 'Pending Payment',
    'status_offline': 'Offline',
    'status_active': 'Active',
    'status_completed': 'Completed',
    'status_expired': 'Expired',

    // ── Location (HomeController) ─────────────────────────────────────────────
    'loc_label': 'Location',
    'loc_disabled': 'Location service is disabled',
    'loc_denied': 'Location permission denied',
    'loc_blocked_title': 'Location Permission Blocked',
    'loc_blocked_msg':
        'Location permission is permanently blocked. Open settings to enable it.',
    'loc_open_settings': 'Open Settings',
    'loc_later': 'Later',
    'loc_error': 'Failed to get location. Try again.',
    'loc_not_found': 'Address not found',
    'loc_error_address': 'Failed to get address',
    'loc_unavailable_title': 'Location Unavailable',
    'loc_unavailable_msg':
        'Enable GPS and make sure location permission is granted, then try again.',

    // ── Connectivity ─────────────────────────────────────────────────────────
    'connection_label': 'Connection',
    'failed_load_status': 'Failed to load status. Showing last data.',

    // ── Payment ───────────────────────────────────────────────────────────────
    'payment_active_title': 'Payment Successful!',
    'payment_active_msg': 'Your work session is now active.',
    'payment_pending_title': 'Payment Pending',
    'payment_pending_msg': 'Transaction is still processing. Check again in a moment.',
    'payment_failed_title': 'Payment Failed',
    'payment_failed_msg': 'Transaction failed. Please try again.',
    'payment_cancelled_title': 'Payment Cancelled',
    'payment_cancelled_msg': 'You closed the payment page before completing.',
    'payment_retry_label': 'Payment',
    'payment_no_url': 'Payment URL not found.',

    // ── Dispatch ──────────────────────────────────────────────────────────────
    'dispatched_title': "You've Been Dispatched!",
    'dispatched_msg': "You're now on duty. Drive safe.",

    // ── Check-in / Check-out ──────────────────────────────────────────────────
    'checkin_success_title': 'Check-In Successful',
    'checkin_success_msg': 'Session activated immediately',
    'checkin_failed_title': 'Check-In Failed',
    'checkout_success_title': 'Check-Out Successful',
    'checkout_failed_title': 'Check-Out Failed',
    'checkout_confirm_title': 'Confirm Check-Out',
    'checkout_confirm_msg':
        'Are you sure you want to end this check-in session?',
    'checkout_confirm_btn': 'Yes, Check-Out',
    'return_success_title': 'Back to Standby',
    'return_failed_title': 'Return Failed',
    'error_processing_title': 'An Error Occurred',
    'error_processing_msg': 'Failed to process request.',

    // ── Biometric / Auth ──────────────────────────────────────────────────────
    'verify_failed_title': 'Verification Failed',
    'verify_failed_msg': 'Biometric authentication is required for check-in.',
    'verify_error_title': 'Verification Failed',
    'verify_error_default': 'Verification failed, please try again.',
    'biometric_error_title': 'Biometric Error',
    'biometric_reason': 'Verify your identity for check-in',
    'lockscreen_title': 'Lock Screen Required',
    'lockscreen_msg':
        'This device does not have a screen lock (PIN, pattern, or fingerprint).\n\n'
            'Go to Settings → Security → Screen Lock, then set up a PIN or biometric first.',
    'lockscreen_btn': 'Understood',

    // ── Logout ────────────────────────────────────────────────────────────────
    'logout_confirm_title': 'Confirm Logout',
    'logout_confirm_msg': 'Are you sure you want to log out?',
    'logout_confirm_btn': 'Yes, Log Out',

    // ── Login validation ──────────────────────────────────────────────────────
    'validation_label': 'Validation',
    'validation_empty': 'Email and password are required',
    'validation_email': 'Invalid email format',

    // ── Misc ──────────────────────────────────────────────────────────────────
    'refresh_failed_title': 'Refresh Failed',
    'refresh_failed_msg': 'Unable to update status.',
  };
}
