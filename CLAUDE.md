# CICO Driver — Project Documentation

Aplikasi Flutter untuk driver **Check-In / Check-Out** dari pool kendaraan.
Driver check-in → bayar via Midtrans Snap → standby → dispatch admin → on_duty → return/checkout.

---

## Stack & Arsitektur

| Lapisan | Teknologi |
|---------|-----------|
| Framework | Flutter (Dart 3) |
| State Management | GetX (`GetxController`, `GetView`, `Obx`) |
| HTTP Client | Dio 5 — singleton `AuthService` via `Get.put(permanent: true)` |
| Storage lokal | `get_storage` (token JWT) |
| Navigasi | GetX named routes (`AppRoutes`) |
| Pattern | MVC — `controllers/`, `views/`, `services/` |

Pola yang dipakai:
- **Controller** mengandung semua business logic dan state (`*.obs`)
- **View** hanya membaca state via `Obx`, tidak ada logic
- **Service** (`AuthService`) hanya HTTP — static helpers `isSuccess()` & `extractMessage()`

---

## Cara Run

```bash
# 1. Install dependencies
flutter pub get

# 2. Jalankan emulator (Android)
flutter emulators --launch Medium_Phone_API_36.1

# 3. Run app (debug mode)
flutter run -d emulator-5554

# 4. Hot reload
r   # di terminal flutter run
```

---

## Struktur Direktori

```
lib/
├── app/routes/          # AppRoutes konstanta + AppPages
├── auth/
│   ├── controllers/     # LoginController
│   ├── services/        # AuthService (singleton) + BiometricService
│   ├── bindings/        # LoginBinding
│   └── views/           # LoginScreen
├── core/
│   ├── config/          # AppConfig (baseUrl)
│   ├── style/           # AppColors
│   ├── utils/           # date_utils, status_helper, auth_helper
│   └── widgets/         # AppNotifier (snackbar, dialog)
├── home/
│   ├── bindings/        # HomeBinding (register BiometricService)
│   ├── controllers/     # HomeController — state utama driver
│   └── views/           # HomeScreen, MainScreen, SnapPaymentPage
├── history/
│   ├── controllers/     # HistoryController — pagination + filter
│   └── views/           # HistoryScreen
└── profile/
    ├── controllers/     # ProfileController
    └── views/           # ProfileScreen
```

---

## Flow Utama: Check-In

```
Driver swipe "Check-In"
  → biometric auth
  → GPS location
  → POST /driver/checkin
      → status: pending_payment
      → response: { data: { payment: { snapRedirectUrl } } }
  → buka SnapPaymentPage (WebView Midtrans)
      → intercept JS untuk QRIS download
      → deteksi hasil: success | pending | failed | closed
  → _handleSnapPaymentResult
      → refreshSessionStatus()
      → status berubah ke on_duty / standby
```

---

## Status Driver

| Status | Warna | Aksi yang tersedia |
|--------|-------|--------------------|
| `offline` | — | Swipe Check-In |
| `pending_payment` | amber | Lanjut Pembayaran |
| `standby` | biru | Swipe Check-Out |
| `on_duty` | hijau | Return (biru) + Check-Out (merah) |

Status di-poll setiap **8 detik** saat `pending_payment`.
`remainingMinutes` di-countdown lokal setiap menit.

---

## API Endpoints

Base URL: `https://api.cico-api.my.id/api/v1`

| Method | Path | Fungsi |
|--------|------|--------|
| `POST` | `/auth/login` | Login, dapat accessToken + refreshToken |
| `POST` | `/auth/refresh` | Refresh token (auto via Dio interceptor) |
| `POST` | `/auth/logout` | Logout |
| `GET` | `/auth/me` | Data profil driver |
| `GET` | `/driver/dashboard` | Status + sesi aktif driver |
| `POST` | `/driver/checkin` | Check-in, dapat snap URL pembayaran |
| `POST` | `/driver/checkin/checkout` | Check-out |
| `POST` | `/driver/checkin/return` | Return ke standby dari on_duty |
| `GET` | `/driver/checkin/history` | Riwayat sesi (pagination + filter tanggal) |

**Response format:**
```json
// Sukses
{ "success": true, "data": { ... }, "message": "..." }

// Error
{ "success": false, "statusCode": 400, "error": "Bad Request", "message": "..." }
// message bisa array untuk validation errors: ["field must be...", "..."]
```

---

## Dependency Injection

`AuthService` di-register **sekali** di `main.dart` sebagai singleton permanen:
```dart
Get.put<AuthService>(AuthService(), permanent: true);
```
Semua controller pakai `Get.find<AuthService>()` — tidak ada instansiasi baru.

`BiometricService` di-register di `HomeBinding`.

---

## Key Design Decisions

- **SSL bypass** hanya aktif di `kDebugMode` (untuk emulator sandbox Midtrans)
- **Location cache** 10 menit via `_locationTimestamp` — tidak fetch GPS setiap aksi
- **`activeAction: DriverAction`** enum — bukan bool, agar setiap button tahu aksi mana yang aktif
- **`AuthService.isSuccess()`** static — validasi response bisa dipakai tanpa inject service
- **`StatusHelper`** — satu sumber kebenaran warna + label per status driver
- **`AuthHelper.confirmAndLogout()`** — dialog + navigasi logout dipisah dari service layer
