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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header Card
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // ROW 1 — Avatar & User Info
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=1961&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.black12,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.userName.value.isEmpty
                                      ? 'Hey, User!'
                                      : 'Hey, ${controller.userName.value}!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  controller.userEmail.value.isEmpty
                                      ? 'Admin'
                                      : controller.userEmail.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // ROW 2 — Time Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TimeItem(
                            label: 'Start Time',
                            time: controller.startTime.value,
                          ),
                          const SizedBox(width: 24),
                          const Text(
                            '---',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 24),
                          _TimeItem(
                            label: 'End Time',
                            time: controller.endTime.value,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Status Text
              Obx(
                () => Text(
                  controller.isCheckedIn.value ? 'ACTIVE' : 'NOT ACTIVE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: controller.isCheckedIn.value
                        ? const Color(0xFF22C55E)
                        : Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Active
              Obx(() {
                if (controller.isCheckedIn.value) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE5E5E5),
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox(height: 100);
              }),

              const SizedBox(height: 32),

              // QRIS Section
              Obx(() {
                if (controller.checkInStatus.value == 'waiting_for_payment' &&
                    controller.snapToken.isNotEmpty) {
                  return Column(
                    children: [
                      const Text(
                        'Lakukan pembayaran dengan QRIS berikut',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data:
                              'https://simulator.sandbox.midtrans.com/v2/qris/index?token=${controller.snapToken.value}',
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.L,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tunggu beberapa detik setelah pembayaran berhasil',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              const Spacer(),

              // Swipe Button
              Obx(() {
                final isProcessing = controller.isProcessing.value;
                final isCheckedIn = controller.isCheckedIn.value;
                final status = controller.checkInStatus.value;
                final token = controller.snapToken.value;
                print("token snap: $token");

                String buttonText = "Swipe untuk Check-In";
                Color thumbColor = Colors.red;
                Color trackColor = Colors.black;

                if (status == 'waiting_for_payment') {
                  buttonText = "Menunggu Pembayaran...";
                  thumbColor = Colors.green;
                  trackColor = Colors.black;
                } else if (isCheckedIn) {
                  buttonText = "Swipe untuk Check-Out";
                  thumbColor = Colors.red;
                  trackColor = Colors.red.withOpacity(0.5);
                }

                return SwipeButton.expand(
                  thumb: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumbColor,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  activeThumbColor: thumbColor,
                  activeTrackColor: trackColor,
                  height: 64,
                  // enabled: !isProcessing &&
                  //     status != 'waiting_for_payment',
                  onSwipe: () async {
                    controller.isProcessing.value = true;
                    try {
                      await controller.toggleCheckInOut();
                    } catch (e) {
                      Get.snackbar('Error', 'Gagal memproses: $e');
                    } finally {
                      controller.isProcessing.value = false;
                      await controller.refreshSessionStatus();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isProcessing) ...[
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  final String label;
  final String time;

  const _TimeItem({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          time.isEmpty ? '--:--' : time,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
