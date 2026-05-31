import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:get/get.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
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
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.manualRefresh,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 18,
                    right: 18,
                    bottom: 8,
                  ),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 14),
                      _buildLocationRow(),
                      const SizedBox(height: 16),
                      _buildDutyStage(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
            _buildActionArea(),
          ],
        );
      }),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Obx(() {
      final name = controller.userName.value;
      final initials = name.trim().isEmpty
          ? '?'
          : name
                .trim()
                .split(RegExp(r'\s+'))
                .take(2)
                .map((w) => w[0].toUpperCase())
                .join();
      return Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.brand700],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(fontFamily: 'SpaceGrotesk',
                  color: const Color(0xFFEAFBFB),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name.isEmpty ? 'Driver' : name,
                  style: TextStyle(fontFamily: 'SpaceGrotesk',
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Obx(() {
            final spinning = controller.isRefreshing.value;
            return GestureDetector(
              onTap: controller.manualRefresh,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: spinning ? 1.0 : 0.0,
                  duration: spinning
                      ? const Duration(milliseconds: 600)
                      : Duration.zero,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: spinning ? AppColors.brand600 : AppColors.ink2,
                  ),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  // ── Location row ────────────────────────────────────────────────────────────
  Widget _buildLocationRow() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    controller.currentAddress.value.isEmpty
                        ? 'Getting location...'
                        : controller.currentAddress.value,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Duty Stage card ─────────────────────────────────────────────────────────
  Widget _buildDutyStage() {
    return Obx(() {
      final status = controller.checkInStatus.value;
      final cfg = _stageConfig(status);
      final hero = _heroText(status, controller.remainingMinutes.value);
      final isTimerStatus = status == 'standby' || status == 'on_duty';

      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: cfg.gradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -130,
              right: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [cfg.glowColor, Colors.transparent],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status tag + plate
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cfg.dotColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cfg.tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(
                        () => Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.directions_car_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.vehicleNumber.value.isEmpty
                                    ? '— —'
                                    : controller.vehicleNumber.value,
                                style: TextStyle(fontFamily: 'SpaceGrotesk',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hero
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.heroKicker,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            hero,
                            style: TextStyle(fontFamily: 'SpaceGrotesk',
                              color: Colors.white,
                              fontSize: status == 'pending_payment' ? 52 : 72,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          if (isTimerStatus) ...[
                            const SizedBox(width: 12),
                            const Text(
                              'HRS : MIN',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cfg.sub,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Perforated divider
                const SizedBox(height: 20),
                _PerforatedDivider(
                  lineColor: Colors.white.withValues(alpha: 0.32),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                  child: Builder(builder: (_) {
                    final f1l = status == 'pending_payment' ? 'METHOD' : 'CHECK-IN';
                    final f1v = status == 'pending_payment'
                        ? 'QRIS'
                        : (controller.startTime.value.isEmpty ? '--:--' : controller.startTime.value);
                    final f2l = status == 'pending_payment' ? 'DUE' : 'EXPIRES';
                    final f2v = status == 'pending_payment'
                        ? 'NOW'
                        : (controller.endTime.value.isEmpty ? '--:--' : controller.endTime.value);
                    return _StageFooter(f1l: f1l, f1v: f1v, f2l: f2l, f2v: f2v);
                  }),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Action swipe buttons ────────────────────────────────────────────────────
  Widget _buildActionArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Obx(() {
        final action = controller.activeAction.value;
        final status = controller.checkInStatus.value;
        final anyBusy = action != DriverAction.none;

        if (status == 'on_duty') {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _swipeBtn(
                label: action == DriverAction.returnStandby
                    ? 'Returning...'
                    : 'SWIPE TO RETURN',
                color: AppColors.info,
                icon: Icons.reply_rounded,
                isBusy: action == DriverAction.returnStandby,
                disabled: anyBusy,
                onSwipe: controller.returnToStandby,
                compact: true,
              ),
              const SizedBox(height: 10),
              _swipeBtn(
                label: action == DriverAction.checkout
                    ? 'Checking Out...'
                    : 'SWIPE TO CHECK-OUT',
                color: AppColors.danger,
                icon: Icons.logout_rounded,
                isBusy: action == DriverAction.checkout,
                disabled: anyBusy,
                onSwipe: controller.checkOutFromDuty,
                compact: true,
              ),
            ],
          );
        }

        final Color color;
        final String label;
        switch (status) {
          case 'standby':
            color = AppColors.danger;
            label = 'SWIPE TO CHECK-OUT';
            break;
          case 'pending_payment':
            color = AppColors.warn;
            label = 'SWIPE TO PAY';
            break;
          default:
            color = AppColors.ok;
            label = 'SWIPE TO CHECK-IN';
        }

        return _swipeBtn(
          label: anyBusy ? 'Please wait...' : label,
          color: color,
          icon: Icons.double_arrow_rounded,
          isBusy: anyBusy,
          disabled: false,
          onSwipe: controller.toggleCheckInOut,
          compact: false,
        );
      }),
    );
  }

  Widget _swipeBtn({
    required String label,
    required Color color,
    required IconData icon,
    required bool isBusy,
    required bool disabled,
    required VoidCallback onSwipe,
    required bool compact,
  }) {
    final h = compact ? 58.0 : 68.0;

    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(h),
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.38),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: SwipeButton.expand(
        height: h,
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.45),
        activeThumbColor: Colors.white,
        inactiveThumbColor: Colors.white.withValues(alpha: 0.65),
        thumbPadding: const EdgeInsets.all(4),
        elevationThumb: 5,
        elevationTrack: 0,
        duration: const Duration(milliseconds: 200),
        onSwipe: (disabled || isBusy) ? null : onSwipe,
        thumb: isBusy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2.2,
                ),
              )
            : Icon(icon, color: color, size: compact ? 22 : 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: SizedBox(
                        height: 2,
                        child: CustomPaint(
                          painter: _DashedLinePainter(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: disabled ? 0.55 : 1.0),
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: SizedBox(
                        height: 2,
                        child: CustomPaint(
                          painter: _DashedLinePainter(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Stage configuration ─────────────────────────────────────────────────────────
class _StageConfig {
  final Gradient gradient;
  final Color glowColor;
  final Color shadowColor;
  final Color dotColor;
  final String tag;
  final String sub;
  final String heroKicker;
  const _StageConfig({
    required this.gradient,
    required this.glowColor,
    required this.shadowColor,
    required this.dotColor,
    required this.tag,
    required this.sub,
    required this.heroKicker,
  });
}

_StageConfig _stageConfig(String status) {
  switch (status) {
    case 'pending_payment':
      return _StageConfig(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7A53C), Color(0xFFE07B0E)],
        ),
        glowColor: Colors.white.withValues(alpha: 0.22),
        shadowColor: const Color(0xFFF7A53C).withValues(alpha: 0.35),
        dotColor: const Color(0xFFFFE7C2),
        tag: 'PENDING PAYMENT',
        sub: 'Complete payment to activate',
        heroKicker: 'AMOUNT DUE',
      );
    case 'standby':
      return _StageConfig(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4385F7), Color(0xFF2151D6)],
        ),
        glowColor: Colors.white.withValues(alpha: 0.20),
        shadowColor: const Color(0xFF4385F7).withValues(alpha: 0.35),
        dotColor: const Color(0xFFCFE0FF),
        tag: 'STANDBY',
        sub: 'Waiting for dispatch',
        heroKicker: 'REMAINING TIME',
      );
    case 'on_duty':
      return _StageConfig(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1AB877), Color(0xFF0B8957)],
        ),
        glowColor: Colors.white.withValues(alpha: 0.22),
        shadowColor: const Color(0xFF1AB877).withValues(alpha: 0.35),
        dotColor: const Color(0xFFC7F6E3),
        tag: 'ON DUTY',
        sub: "You're live — drive safe",
        heroKicker: 'REMAINING TIME',
      );
    default:
      return _StageConfig(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.panelInk2, AppColors.panelInk],
        ),
        glowColor: const Color(0xFFFF6B61).withValues(alpha: 0.16),
        shadowColor: AppColors.panelInk.withValues(alpha: 0.4),
        dotColor: const Color(0xFFFF6B61),
        tag: 'OFFLINE',
        sub: 'Start your shift to go online',
        heroKicker: 'NOT CLOCKED IN',
      );
  }
}

String _heroText(String status, int? remainingMinutes) {
  switch (status) {
    case 'pending_payment':
      return 'Rp 35.000';
    case 'standby':
    case 'on_duty':
      if (remainingMinutes == null) return '--:--';
      final h = remainingMinutes ~/ 60;
      final m = remainingMinutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    default:
      return '--:--';
  }
}

// ── Stage footer ────────────────────────────────────────────────────────────────
class _StageFooter extends StatelessWidget {
  final String f1l, f1v, f2l, f2v;
  const _StageFooter({
    required this.f1l,
    required this.f1v,
    required this.f2l,
    required this.f2v,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _field(f1l, f1v, left: true),
        Container(
          width: 1,
          height: 30,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _field(f2l, f2v, left: false),
      ],
    );
  }

  Widget _field(String label, String value, {required bool left}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: left
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontFamily: 'SpaceGrotesk',
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perforated divider ─────────────────────────────────────────────────────────
class _PerforatedDivider extends StatelessWidget {
  final Color lineColor;
  const _PerforatedDivider({required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DashedLinePainter(color: lineColor)),
          ),
          Positioned(left: -11, child: _Notch(color: color)),
          Positioned(right: -11, child: _Notch(color: color)),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  final Color color;
  const _Notch({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    double x = 0;
    const dashW = 6.0, gapW = 5.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
