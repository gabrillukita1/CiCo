import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/core/utils/status_helper.dart';
import 'package:cico_project/home/controllers/home_controller.dart'; // juga mengekspor DriverAction
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

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
          child: Obx(() {
            if (controller.isInitializing.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading dashboard...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
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
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Obx(() {
        final action = controller.activeAction.value; // DriverAction enum
        final status = controller.checkInStatus.value;
        final anyBusy = action != DriverAction.none;

        // ON DUTY: dua swipe button — masing-masing tahu aksinya sendiri
        if (status == 'on_duty') {
          final returningNow = action == DriverAction.returnStandby;
          final checkingOutNow = action == DriverAction.checkout;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwipeButton.expand(
                height: 58,
                activeTrackColor: AppColors.surface,
                activeThumbColor: AppColors.standby,
                elevationThumb: 2,
                onSwipe: anyBusy ? null : controller.returnToStandby,
                thumb: returningNow
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                      )
                    : const Icon(Icons.reply_rounded, color: AppColors.surface),
                child: Text(
                  returningNow ? 'Kembali ke Standby...' : 'Swipe untuk Return',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SwipeButton.expand(
                height: 58,
                activeTrackColor: AppColors.surface,
                activeThumbColor: Colors.red.shade400,
                elevationThumb: 2,
                onSwipe: anyBusy ? null : controller.checkOutFromDuty,
                thumb: checkingOutNow
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                      )
                    : Icon(Icons.logout_rounded, color: AppColors.surface),
                child: Text(
                  checkingOutNow ? 'Check-Out...' : 'Swipe untuk Check-Out',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
        }

        // Status lain: satu swipe button
        Color thumbColor;
        String text;

        switch (status) {
          case 'standby':
            thumbColor = Colors.blueGrey.shade600;
            text = 'Swipe untuk Check-Out';
            break;
          case 'pending_payment':
            thumbColor = AppColors.waiting;
            text = 'Lanjut Pembayaran';
            break;
          case 'offline':
          default:
            thumbColor = AppColors.active;
            text = 'Swipe untuk Check-In';
        }

        return SwipeButton.expand(
          height: 68,
          activeTrackColor: AppColors.surface,
          activeThumbColor: thumbColor,
          elevationThumb: 2,
          onSwipe: anyBusy ? null : controller.toggleCheckInOut,
          thumb: anyBusy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                )
              : const Icon(Icons.double_arrow_rounded, color: AppColors.surface),
          child: Text(
            anyBusy ? 'Mohon Tunggu...' : text,
            style: const TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        );
      }),
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
            color: Colors.black.withValues(alpha: 0.04),
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
                _buildTimeDetail("Mulai", controller.startTime.value),
                const VerticalDivider(color: AppColors.border, thickness: 1),
                _buildTimeDetail("Berakhir", controller.endTime.value),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// Dipanggil dari dalam Obx di getHeaderSection() — reactive terhadap userName.
  Widget _buildAvatar() {
    final name = controller.userName.value;
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 3),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.userName.value.isEmpty ? 'Hey, Driver!' : 'Hey, ${controller.userName.value}!',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          if (controller.vehicleNumber.value.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 12, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(
                  controller.vehicleNumber.value,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          const SizedBox(height: 4),
          _buildLocationRow(),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.8)),
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
      final info = StatusHelper.of(controller.checkInStatus.value);

      return Column(
        children: [
          const SizedBox(height: 24),
          _buildStatusVisual(info.color, info.icon),
          const SizedBox(height: 20),
          _buildStatusBadge(info.displayText, info.color),
          if (controller.remainingMinutes.value != null) ...[
            const SizedBox(height: 20),
            _buildRemainingTime(controller.remainingMinutes.value!, info.color),
          ],
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildRemainingTime(int minutes, Color color) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'
        : '00:${m.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                'Sisa Waktu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            h > 0 ? 'jam  :  menit' : 'menit',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusVisual(Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.05))),
        Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1))),
        Icon(icon, size: 90, color: color),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
      ),
    );
  }
}