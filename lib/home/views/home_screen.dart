import 'package:cico_project/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: getHeaderSection(),
            ),

            // Status section (aktif/tidak aktif)
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.manualRefresh,
                color: Colors.green,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(Get.context!).size.height * 0.6,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(child: getStatusSection()),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Swipe button + logout
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final isProcessing = controller.isProcessing.value;
                    final isCheckedIn = controller.isCheckedIn.value;
                    final isWaiting =
                        controller.checkInStatus.value == 'waiting_for_payment';

                    Color trackColor = Colors.black;
                    Color thumbColor;
                    String text;

                    if (isWaiting) {
                      thumbColor = Colors.orange;
                      text = 'Swipe untuk Lanjut Pembayaran';
                    } else if (isCheckedIn) {
                      thumbColor = Colors.red;
                      text = 'Swipe untuk Check-Out';
                    } else {
                      thumbColor = Colors.green;
                      text = 'Swipe untuk Check-In';
                    }

                    return SwipeButton.expand(
                      height: 64,
                      activeTrackColor: trackColor,
                      activeThumbColor: thumbColor,
                      onSwipe: controller.toggleCheckInOut, // ✅ tetap aktif

                      thumb: const Icon(
                        Icons.double_arrow_rounded,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: controller.logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getHeaderSection() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1580489944761-15a19d654956',
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 36, color: Colors.black12),
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimeItem(
                  label: 'Start Time',
                  time: controller.startTime.value,
                ),
                const SizedBox(width: 24),
                const Text('---', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                _TimeItem(label: 'End Time', time: controller.endTime.value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget getStatusSection() {
    return Obx(() {
      final bool isActive = controller.isCheckedIn.value;
      final bool isWaiting =
          controller.checkInStatus.value == 'waiting_for_payment';

      // Status text & color
      String statusText;
      Color statusColor;
      String imagePath;
      if (isActive) {
        statusText = 'ACTIVE';
        statusColor = const Color(0xFF22C55E);
        imagePath = 'assets/images/success_icon.png';
      } else if (isWaiting) {
        statusText = 'WAITING FOR PAYMENT';
        statusColor = Colors.orange;
        imagePath = 'assets/images/waiting_for_payment.png';
      } else {
        statusText = 'NOT ACTIVE';
        statusColor = Colors.redAccent;
        imagePath = 'assets/images/reject_icon.png';
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5E5E5),
                ),
              ),
              Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      );
    });
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
