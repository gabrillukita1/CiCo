import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/core/utils/status_helper.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:cico_project/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(20, top + 8, 20, 14),
            child: Row(
              children: [
                Text('Profile',
                  style: TextStyle(fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700, fontSize: 30,
                    letterSpacing: -0.5, color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: controller.loadProfile,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.ink2),
                  ),
                ),
              ],
            ),
          ),
          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final p = controller.profile.value;
              if (p == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text('Failed to load profile', style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                child: Column(
                  children: [
                    _buildDriverIdCard(p),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Account',
                      children: [
                        _InfoRow(icon: Icons.alternate_email_rounded, label: 'EMAIL', value: p['email'] ?? '-'),
                        _InfoRow(icon: Icons.phone_rounded, label: 'PHONE', value: p['phone'] ?? '-', last: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Vehicle',
                      children: [
                        _InfoRow(icon: Icons.pin_rounded, label: 'PLATE NUMBER', value: p['vehicleNumber'] ?? '-', mono: true),
                        _InfoRow(icon: Icons.directions_car_filled_rounded, label: 'VEHICLE TYPE',
                            value: p['vehicleType'] ?? '-', last: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Logout button
                    GestureDetector(
                      onTap: controller.logout,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.30), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20, color: AppColors.danger),
                            SizedBox(width: 9),
                            Text('Log out',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 15.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Driver ID boarding pass ────────────────────────────────────────────────
  Widget _buildDriverIdCard(Map<String, dynamic> p) {
    final name = p['name'] as String? ?? 'Driver';
    final role = p['role'] as String? ?? 'Driver';
    final vehicleType = p['vehicleType'] as String? ?? '';
    final plate = p['vehicleNumber'] as String? ?? '— — —';
    final status = p['status'] as String? ?? 'offline';
    final info = StatusHelper.of(status);
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.panelInk2, AppColors.panelInk],
        ),
      ),
      child: Stack(
        children: [
          // Glow circle
          Positioned(
            top: -130, right: -80,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.45), Colors.transparent],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DRIVER ID',
                          style: TextStyle(color: Colors.white60, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 2.0)),
                        // Status pill
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white70)),
                              const SizedBox(width: 6),
                              Text(info.label,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Avatar + name
                    Row(
                      children: [
                        Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.brand700],
                            ),
                          ),
                          child: Center(
                            child: Text(initials,
                              style: TextStyle(fontFamily: 'SpaceGrotesk',
                                color: const Color(0xFFEAFBFB),
                                fontWeight: FontWeight.w600, fontSize: 25,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                style: TextStyle(fontFamily: 'SpaceGrotesk',
                                  color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w600, letterSpacing: -0.3,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$role${vehicleType.isNotEmpty ? ' · $vehicleType' : ''}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    // Plate number
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLATE NUMBER',
                          style: TextStyle(color: Colors.white54, fontSize: 9.5,
                              fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                        const SizedBox(height: 4),
                        Text(plate,
                          style: TextStyle(fontFamily: 'SpaceGrotesk',
                            color: Colors.white, fontWeight: FontWeight.w700,
                            fontSize: 25, letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Perforated divider
              const SizedBox(height: 18),
              _PerforatedDivider(
                lineColor: Colors.white.withValues(alpha: 0.22),
                notchColor: AppColors.background,
              ),
              // ID / VALID footer
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final code = '${p['driverCode'] ?? p['id'] ?? '-'}';
                        Clipboard.setData(ClipboardData(text: code));
                        AppNotifier.info('Kode Disalin', 'Kode driver berhasil disalin ke clipboard.');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('KODE · ${p['driverCode'] ?? p['id'] ?? '-'}',
                            style: TextStyle(fontFamily: 'SpaceGrotesk',
                                color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 5),
                          const Icon(Icons.copy_rounded, size: 11, color: Colors.white38),
                        ],
                      ),
                    ),
                    Text('VALID',
                      style: TextStyle(fontFamily: 'SpaceGrotesk',
                          color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.primary),
                  ),
                  const SizedBox(width: 11),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.ink)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.lineSoft),
          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                        letterSpacing: 1.4, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(value,
                    style: mono
                        ? TextStyle(fontFamily: 'SpaceGrotesk',fontSize: 15.5, color: AppColors.ink, fontWeight: FontWeight.w700)
                        : const TextStyle(fontSize: 15.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
              ],
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
  final Color notchColor;
  const _PerforatedDivider({required this.lineColor, required this.notchColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _DashedPainter(color: lineColor))),
          Positioned(left: -11, child: _Notch(color: notchColor)),
          Positioned(right: -11, child: _Notch(color: notchColor)),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  final Color color;
  const _Notch({required this.color});
  @override
  Widget build(BuildContext context) =>
      Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _DashedPainter extends CustomPainter {
  final Color color;
  const _DashedPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), p);
      x += 11;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Barcode painter ────────────────────────────────────────────────────────────
class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final widths = [2.0, 4.0, 2.0, 5.0, 2.0, 3.0, 2.0, 4.0, 2.0, 4.0, 2.0, 5.0, 2.0, 3.0, 2.0, 4.0];
    double x = 0;
    bool fill = true;
    for (final w in widths) {
      if (fill) canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w + 2;
      fill = !fill;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
