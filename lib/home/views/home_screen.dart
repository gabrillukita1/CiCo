import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';

class HomeScreen extends GetView<HomeController> with WidgetsBindingObserver {
  HomeScreen({super.key}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.manualRefresh();
    }
  }
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, Colors.blueGrey.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: getHeaderSection(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.manualRefresh,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: getStatusSection(),
                    ),
                  ),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final isProcessing = controller.isProcessing.value;
            final isCheckedIn = controller.isCheckedIn.value;
            final isWaiting = controller.checkInStatus.value == 'waiting_for_payment';

            Color thumbColor = AppColors.active;
            String text = 'Swipe untuk Check-In';

            if (isWaiting) {
              thumbColor = AppColors.waiting;
              text = 'Lanjut Pembayaran';
            } else if (isCheckedIn) {
              thumbColor = AppColors.inactive;
              text = 'Swipe untuk Check-Out';
            }

            return SwipeButton.expand(
              height: 68,
              activeTrackColor: AppColors.surface,
              activeThumbColor: thumbColor,
              elevationThumb: 2,
              onSwipe: controller.toggleCheckInOut,
              thumb: isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                    )
                  : const Icon(Icons.double_arrow_rounded, color: AppColors.surface),
              child: Text(
                isProcessing ? "Mohon Tunggu..." : text,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: controller.logout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.textSub),
        label: const Text(
          'Logout dari Akun',
          style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget getHeaderSection() {
    return Obx(() => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              _buildUserInfo(),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, thickness: 0.8, color: AppColors.border),
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeDetail("Start Time", controller.startTime.value),
                const VerticalDivider(color: AppColors.border, thickness: 1),
                _buildTimeDetail("End Time", controller.endTime.value),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 3),
      ),
      child: const CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1580489944761-15a19d654956'),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.userName.value.isEmpty ? 'Hey, User!' : 'Hey, ${controller.userName.value}!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          Text(
            controller.userEmail.value.isEmpty ? 'Admin' : controller.userEmail.value,
            style: const TextStyle(fontSize: 13, color: AppColors.textSub),
          ),
          const SizedBox(height: 6),
          _buildLocationRow(),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary.withOpacity(0.8)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            controller.currentAddress.value.isEmpty ? 'Mengambil lokasi...' : controller.currentAddress.value,
            style: const TextStyle(fontSize: 11, color: AppColors.textSub),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDetail(String label, String time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(time.isEmpty ? '--:--' : time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget getStatusSection() {
    return Obx(() {
      final bool isActive = controller.isCheckedIn.value;
      final bool isWaiting = controller.checkInStatus.value == 'waiting_for_payment';

      Color statusColor = AppColors.inactive;
      IconData statusIcon = Icons.cancel_rounded;
      String statusText = 'NOT ACTIVE';

      if (isActive) {
        statusColor = AppColors.active;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'ACTIVE';
      } else if (isWaiting) {
        statusColor = AppColors.waiting;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'WAITING FOR PAYMENT';
      }

      return Column(
        children: [
          const SizedBox(height: 40),
          _buildStatusVisual(statusColor, statusIcon),
          const SizedBox(height: 32),
          _buildStatusBadge(statusText, statusColor),
          const SizedBox(height: 12),
          Text(
            isWaiting
                ? "Selesaikan pembayaran untuk mengaktifkan sesi kerja."
                : (isActive ? "Sesi kerja Anda sedang berjalan." : "Silahkan melakukan Check-In."),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          const SizedBox(height: 40),
        ],
      );
    });
  }

  Widget _buildStatusVisual(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.05))),
        Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1))),
        Icon(icon, size: 90, color: color),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }
}