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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      getHeaderSection(),

                      const SizedBox(height: 32),

                      getStatusSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Obx(() {
                final isProcessing = controller.isProcessing.value;
                final isCheckedIn = controller.isCheckedIn.value;

                return SwipeButton.expand(
                  height: 64,
                  activeTrackColor: Colors.black,
                  thumb: Icon(
                    Icons.double_arrow_rounded,
                    color: Colors.white,
                  ),
                  activeThumbColor: isCheckedIn ? Colors.red : Colors.green,
                  onSwipe: controller.toggleCheckInOut,
                  child: Center(
                    child: isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isCheckedIn
                          ? 'Swipe untuk Check-Out'
                          : 'Swipe untuk Check-In',
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
                  label: const Text('Logout',
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getHeaderSection() {
    return
      Obx(() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1580489944761-15a19d654956',
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
                            : 'Hey, ${controller.userName.value}',
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
                const Text('---',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 24),
                _TimeItem(
                  label: 'End Time',
                  time: controller.endTime.value,
                ),
              ],
            ),
          ],
        ),
      ));
  }

  Widget getStatusSection() {
    return Obx(() => Column(
      children: [
        Text(
          controller.isCheckedIn.value ? 'ACTIVE' : 'NOT ACTIVE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: controller.isCheckedIn.value
                ? const Color(0xFF22C55E)
                : Colors.redAccent,
          ),
        ),

        const SizedBox(height: 16),

        Stack(
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
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                controller.isCheckedIn.value
                    ? 'assets/images/success_icon.png'
                    : 'assets/images/reject_icon.png',
              ),
            ),
          ],
        ),
      ],
    ));
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
