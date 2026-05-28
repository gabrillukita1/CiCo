import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ── Filter chip data ────────────────────────────────────────────────────────
const _filters = [
  (label: 'All', filter: DateFilter.all),
  (label: 'Today', filter: DateFilter.today),
  (label: 'This Week', filter: DateFilter.thisWeek),
  (label: 'This Month', filter: DateFilter.thisMonth),
];

class HistoryScreen extends GetView<HistoryController> {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Session History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ────────────────────────────────────
          _FilterBar(controller: controller),
          const Divider(height: 1, color: AppColors.border),

          // ── List ──────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (controller.sessionList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 56,
                        color: AppColors.textSub.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No session history yet',
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadHistory,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount:
                      controller.sessionList.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == controller.sessionList.length) {
                      return Obx(
                        () => controller.isLoadingMore.value
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    }
                    return _SessionCard(session: controller.sessionList[i]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final HistoryController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Obx(() {
          final active = controller.selectedFilter.value;
          return Row(
            children: [
              // Preset chips
              ..._filters.map((f) => _chip(
                    context,
                    label: f.label,
                    isSelected: active == f.filter,
                    onTap: () => controller.setFilter(f.filter),
                  )),

              // Custom chip
              _chip(
                context,
                label: _customLabel(controller),
                isSelected: active == DateFilter.custom,
                icon: Icons.calendar_month_rounded,
                onTap: () => _pickCustomRange(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _customLabel(HistoryController c) {
    if (c.selectedFilter.value == DateFilter.custom &&
        c.customStart.value != null &&
        c.customEnd.value != null) {
      final fmt = DateFormat('dd MMM');
      return '${fmt.format(c.customStart.value!)} – ${fmt.format(c.customEnd.value!)}';
    }
    return 'Custom';
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: controller.customStart.value != null
          ? DateTimeRange(
              start: controller.customStart.value!,
              end: controller.customEnd.value!,
            )
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.setFilter(DateFilter.custom, range: picked);
    }
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session Card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final status = session['status'] as String? ?? 'expired';
    final payment = session['payment'] as Map<String, dynamic>?;
    final dispatches = (session['dispatches'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final payStatus = payment?['status'] as String?;
    final isFaded = payStatus != null &&
        payStatus != 'success' &&
        payStatus != 'pending';

    final Color accentColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status) {
      case 'active':
        accentColor = AppColors.active;
        statusLabel = 'Active';
        statusIcon = Icons.radio_button_checked_rounded;
        break;
      case 'pending_payment':
        accentColor = AppColors.waiting;
        statusLabel = 'Pending Payment';
        statusIcon = Icons.schedule_rounded;
        break;
      case 'expired':
      default:
        accentColor = AppColors.textSub;
        statusLabel = 'Expired';
        statusIcon = Icons.cancel_outlined;
    }

    return Opacity(
      opacity: isFaded ? 0.45 : 1.0,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          _buildHeader(accentColor, statusLabel, statusIcon),

          // ── Times ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTimeCell(
                    label: 'Check-in',
                    value: _formatTime(session['checkinAt']),
                    date: _formatDate(session['checkinAt']),
                  ),
                ),
                _buildDurationCenter(
                  session['checkinAt'],
                  session['checkoutAt'],
                  _showCheckout(status, payment),
                ),
                Expanded(
                  child: _buildTimeCell(
                    label: 'Check-out',
                    value: _showCheckout(status, payment)
                        ? (status == 'active'
                            ? '—'
                            : _formatTime(session['checkoutAt']))
                        : '—',
                    date: _showCheckout(status, payment)
                        ? (status == 'active'
                            ? 'Ongoing'
                            : _formatDate(session['checkoutAt']))
                        : '',
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Payment ─────────────────────────────────────
          if (payment != null) ...[
            _buildDivider(),
            _buildPaymentRow(payment),
          ],

          // ── Dispatch ────────────────────────────────────
          if (dispatches.isNotEmpty) ...[
            _buildDivider(),
            _buildDispatchExpansion(dispatches),
          ],

          const SizedBox(height: 4),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(Color accentColor, String statusLabel, IconData statusIcon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Icon(statusIcon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const Spacer(),
          Text(
            _formatFullDate(session['checkinAt']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCell({
    required String label,
    required String value,
    required String date,
    bool alignRight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignRight ? 16 : 0,
        right: alignRight ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    final payStatus = payment['status'] as String? ?? 'pending';
    final amount = payment['amount'];
    final paymentType = payment['paymentType'] as String?;

    final Color badgeColor;
    final String badgeLabel;

    switch (payStatus) {
      case 'success':
        badgeColor = AppColors.active;
        badgeLabel = 'Success';
        break;
      case 'pending':
        badgeColor = AppColors.waiting;
        badgeLabel = 'Pending';
        break;
      case 'failed':
        badgeColor = AppColors.inactive;
        badgeLabel = 'Failed';
        break;
      case 'expired':
        badgeColor = AppColors.textSub;
        badgeLabel = 'Expired';
        break;
      case 'cancelled':
        badgeColor = AppColors.inactive;
        badgeLabel = 'Cancelled';
        break;
      default:
        badgeColor = AppColors.textSub;
        badgeLabel = payStatus;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: (payStatus == 'pending' || payStatus == 'success')
                            ? AppColors.textMain
                            : AppColors.textSub.withValues(alpha: 0.4),
                        decoration: (payStatus == 'pending' || payStatus == 'success')
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                        decorationColor: AppColors.textSub.withValues(alpha: 0.4),
                      ),
                    ),
                    if (paymentType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          paymentType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchExpansion(List<Map<String, dynamic>> dispatches) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.waiting.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            size: 16,
            color: AppColors.waiting,
          ),
        ),
        title: const Text(
          'Dispatch',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.waiting.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${dispatches.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.waiting,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, color: AppColors.textSub),
          ],
        ),
        children: dispatches.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final name = d['dispatchedBy']?['name'] as String? ?? 'Admin';
          final time = _formatDateTime(d['dispatchedAt']) ?? '—';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.waiting.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.waiting,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _showCheckout(String status, Map<String, dynamic>? payment) {
    if (status == 'active') return true;
    final payStatus = payment?['status'] as String?;
    return payStatus == 'success';
  }

  Widget _buildDurationCenter(dynamic checkinAt, dynamic checkoutAt, bool showDuration) {
    String duration = '';
    if (showDuration && checkinAt != null && checkoutAt != null) {
      try {
        final ci = DateTime.parse(checkinAt.toString()).toLocal();
        final co = DateTime.parse(checkoutAt.toString()).toLocal();
        final diff = co.difference(ci);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        duration = h > 0 ? '${h}h ${m}m' : '${m}m';
      } catch (_) {}
    }

    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 1, height: 14, color: AppColors.border),
          const SizedBox(height: 4),
          if (duration.isNotEmpty)
            Text(
              duration,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
              textAlign: TextAlign.center,
            )
          else
            Container(width: 1, height: 12, color: AppColors.border),
          const SizedBox(height: 4),
          Container(width: 1, height: 14, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.border,
  );

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _formatDateTime(dynamic value) {
    if (value == null) return null;
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '—';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatFullDate(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('EEE, dd MMM yyyy').format(dt);
    } catch (_) {
      return '—';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    try {
      final num val = num.parse(amount.toString());
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(val);
    } catch (_) {
      return 'Rp $amount';
    }
  }
}
