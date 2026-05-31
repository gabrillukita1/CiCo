import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/core/utils/date_utils.dart' as tz;
import 'package:cico_project/core/utils/status_helper.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _filters = [
  (label: 'All', filter: DateFilter.all),
  (label: 'Today', filter: DateFilter.today),
  (label: 'This Week', filter: DateFilter.thisWeek),
  (label: 'This Month', filter: DateFilter.thisMonth),
];

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryController controller = Get.find<HistoryController>();
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Sticky top bar ──────────────────────────────────────────────
          _buildTopBar(context),
          // ── Filter chips ────────────────────────────────────────────────
          _buildFilterBar(),
          // ── List ────────────────────────────────────────────────────────
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Obx(() {
            final count = controller.sessionList.length;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('History',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700, fontSize: 30,
                    letterSpacing: -0.5, color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.brand600, fontWeight: FontWeight.w700, fontSize: 13,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const Spacer(),
          GestureDetector(
            onTap: controller.loadHistory,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.ink2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Obx(() {
      final active = controller.selectedFilter.value;
      return SizedBox(
        height: 54,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
          children: [
            ..._filters.map((f) => _filterChip(
              label: f.label,
              isActive: active == f.filter,
              onTap: () => controller.setFilter(f.filter),
            )),
            _filterChip(
              label: _customLabel(),
              isActive: active == DateFilter.custom,
              onTap: () => _pickCustomRange(),
              icon: Icons.calendar_today_rounded,
              isCustom: true,
            ),
          ],
        ),
      );
    });
  }

  String _customLabel() {
    if (controller.selectedFilter.value == DateFilter.custom &&
        controller.customStart.value != null &&
        controller.customEnd.value != null) {
      final fmt = DateFormat('dd MMM');
      return '${fmt.format(controller.customStart.value!)} – ${fmt.format(controller.customEnd.value!)}';
    }
    return 'Custom';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: controller.customStart.value != null
          ? DateTimeRange(start: controller.customStart.value!, end: controller.customEnd.value!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary, onPrimary: Colors.white, surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.setFilter(DateFilter.custom, range: picked);
  }

  Widget _filterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: isActive ? AppColors.panelInk : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.panelInk.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: isActive ? Colors.white : AppColors.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final sessions = controller.sessionList;
      final hasMore = controller.hasMore.value;
      final isLoadingMore = controller.isLoadingMore.value;

      if (isLoading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (sessions.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 56,
                  color: AppColors.muted.withValues(alpha: 0.35)),
              const SizedBox(height: 12),
              const Text('No sessions yet',
                  style: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadHistory,
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          itemCount: sessions.length + (hasMore ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == sessions.length) {
              return isLoadingMore
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                    )
                  : const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SessionCard(session: sessions[i]),
            );
          },
        ),
      );
    });
  }
}

// ── Session Card ──────────────────────────────────────────────────────────────
class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});
  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _dispatchOpen = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.session['status'] as String? ?? 'expired';
    final payment = widget.session['payment'] as Map<String, dynamic>?;
    final dispatches = (widget.session['dispatches'] as List? ?? []).cast<Map<String, dynamic>>();
    final payStatus = payment?['status'] as String? ?? '';
    final isFaded = payStatus != 'success' && payStatus != 'pending' && payStatus.isNotEmpty;
    final info = StatusHelper.ofSession(status);

    return Opacity(
      opacity: isFaded ? 0.65 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: status + date ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
              child: Row(
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: info.color.withValues(alpha: 0.13),
                    ),
                    child: Icon(info.icon, size: 15, color: info.color),
                  ),
                  const SizedBox(width: 8),
                  Text(info.label,
                      style: TextStyle(color: info.color, fontWeight: FontWeight.w800, fontSize: 14.5)),
                  const Spacer(),
                  Text(tz.formatDate(widget.session['checkinAt']),
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ],
              ),
            ),
            // ── Check-in / out split ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Row(
                children: [
                  _timeCell('Check-in', _fmtTime(widget.session['checkinAt']), left: true),
                  // Center arrow + duration
                  SizedBox(
                    width: 56,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.keyboard_double_arrow_right_rounded,
                            size: 18, color: isFaded ? AppColors.line : info.color),
                        const SizedBox(height: 3),
                        if (_duration(widget.session['checkinAt'], widget.session['checkoutAt']) != null)
                          Text(
                            _duration(widget.session['checkinAt'], widget.session['checkoutAt'])!,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  _timeCell(
                    'Check-out',
                    status == 'active' ? '—' : _fmtTime(widget.session['checkoutAt']),
                    left: false,
                  ),
                ],
              ),
            ),
            // ── Perforated divider ─────────────────────────────────────────
            _PerforatedDivider(lineColor: AppColors.line, notchColor: AppColors.background),
            // ── Payment row ────────────────────────────────────────────────
            if (payment != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: _buildPaymentRow(payment),
              ),
            // ── Dispatch accordion ─────────────────────────────────────────
            if (dispatches.isNotEmpty) ...[
              Container(height: 1, color: AppColors.lineSoft),
              _buildDispatchRow(dispatches),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeCell(String label, String time, {required bool left}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.4, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(time,
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700, fontSize: 28, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    final payStatus = payment['status'] as String? ?? 'pending';
    final amount = payment['amount'];
    final method = payment['paymentType'] as String?;

    final Color color;
    final String statusLabel;
    switch (payStatus) {
      case 'success': color = AppColors.ok; statusLabel = 'Paid'; break;
      case 'pending': color = AppColors.warn; statusLabel = 'Pending'; break;
      case 'expired': color = AppColors.muted; statusLabel = 'Expired'; break;
      default: color = AppColors.danger; statusLabel = 'Failed';
    }

    final isStruck = payStatus == 'expired' || payStatus == 'failed';

    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long_rounded, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PAYMENT',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.4, color: AppColors.muted)),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    _fmtCurrency(amount),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700, fontSize: 16.5,
                      color: isStruck ? AppColors.muted : AppColors.ink,
                      decoration: isStruck ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.muted,
                    ),
                  ),
                  if (method != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(method.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(statusLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }

  Widget _buildDispatchRow(List<Map<String, dynamic>> dispatches) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _dispatchOpen = !_dispatchOpen),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warnTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_taxi_rounded, size: 19, color: AppColors.warn),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dispatch',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                      Text('${dispatches.length} ${dispatches.length > 1 ? 'dispatches' : 'dispatch'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.warnTint, borderRadius: BorderRadius.circular(999)),
                  child: Text('${dispatches.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.warn)),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _dispatchOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        if (_dispatchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Column(
              children: dispatches.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final name = d['dispatchedBy']?['name'] as String? ?? 'Admin';
                final time = tz.formatDateTime(d['dispatchedAt']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warn),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dispatch by',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4, color: AppColors.muted)),
                              Text(name,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                                      color: AppColors.ink),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Dispatch at',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4, color: AppColors.muted)),
                              Text(time,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _fmtTime(dynamic v) => tz.formatTime(v, fallback: '—');

  String? _duration(dynamic checkin, dynamic checkout) {
    if (checkin == null || checkout == null) return null;
    try {
      final ci = tz.toJakarta(checkin)!;
      final co = tz.toJakarta(checkout)!;
      final diff = co.difference(ci);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return h > 0 ? '${h}h ${m}m' : '${m}m';
    } catch (_) { return null; }
  }

  String _fmtCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(num.parse(amount.toString()));
    } catch (_) { return 'Rp $amount'; }
  }
}

// ── Perforated divider (same as home_screen) ──────────────────────────────────
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
          Positioned(left: -11, child: _NotchCircle(color: notchColor)),
          Positioned(right: -11, child: _NotchCircle(color: notchColor)),
        ],
      ),
    );
  }
}

class _NotchCircle extends StatelessWidget {
  final Color color;
  const _NotchCircle({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 22, height: 22,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
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
