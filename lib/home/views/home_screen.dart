import 'package:cico_project/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('CICO Home'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amber[100],
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.amber[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Text(
                        controller.userName.value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Text(
                        controller.userEmail.value,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Status
            Obx(
              () => Text(
                'Status: ${controller.statusText.value}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: controller.isCheckedIn.value
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Swipe Button
            Obx(() {
              final isProcessing = controller.isProcessing.value;
              final paymentStatus = controller.paymentStatus.value;
              final isCheckedIn = controller.isCheckedIn.value;
              final isPending = paymentStatus == 'pending';

              String buttonText;
              Color buttonColor;
              bool isEnabled = true;

              if (isPending) {
                buttonText = "Menunggu Pembayaran...";
                print("token: ${controller.snapToken.value}");
                buttonColor = Colors.green[700]!;
                // isEnabled = false;
              } else if (isCheckedIn) {
                buttonText = "Swipe untuk Check-Out";
                buttonColor = Colors.amber[700]!;
              } else {
                buttonText = "Swipe untuk Check-In";
                buttonColor = Colors.amber[700]!;
              }

              return Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: buttonColor.withOpacity(0.12),
                  ),
                  child: SwipeButton(
                    thumb: const Icon(Icons.chevron_right, color: Colors.white),
                    activeThumbColor: buttonColor,
                    activeTrackColor: buttonColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    height: 80,
                    enabled:
                        isEnabled &&
                        !isProcessing,
                    onSwipe: isEnabled && !isProcessing
                        ? () async {
                            print('===== SWIPE BERHASIL TERDETEKSI! =====');
                            controller.isProcessing.value = true;
                            try {
                              await controller
                                  .toggleCheckInOut();
                            } catch (e) {
                              print('Swipe error: $e');
                              Get.snackbar('Error', 'Gagal memproses: $e');
                            } finally {
                              controller.isProcessing.value = false;
                              print('Swipe selesai');
                              await controller.refreshSessionStatus();
                            }
                          }
                        : null,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isProcessing) ...[
                            const SizedBox(width: 12),
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // QR + Status Pembayaran
            Obx(() {
              if (controller.paymentStatus.value == 'pending' &&
                  controller.snapToken.isNotEmpty) {
                return Column(
                  children: [
                    const SizedBox(height: 32),
                    const Text(
                      'Silakan bayar menggunakan QRIS berikut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data:
                            'https://simulator.sandbox.midtrans.com/v2/qris/index?token=${controller.snapToken.value}',
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.L,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tunggu beberapa detik setelah pembayaran berhasil',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                );
              }

              // Tampilkan ikon sukses setelah paid
              if (controller.isCheckedIn.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 100,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sesi Aktif!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            }),

            const SizedBox(height: 60),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
