import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
          'History',
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
      body: Obx(() {
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
                  Icons.inbox_rounded,
                  size: 56,
                  color: AppColors.textSub.withOpacity(0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada riwayat sesi',
                  style: TextStyle(color: AppColors.textSub, fontSize: 14),
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
                  () =>
                      controller.isLoadingMore.value
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
              return _sessionCard(controller.sessionList[i]);
            },
          ),
        );
      }),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session) {
    final status = session['status'] as String? ?? 'expired';
    final isPaid = session['isPaid'] == true;
    final payment = session['payment'] as Map<String, dynamic>?;
    final dispatches = (session['dispatches'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          _cardHeader(session, status, isPaid),

          // ── Check-in / Check-out times ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _timeRow(
                  Icons.login_rounded,
                  'Check-in',
                  _formatDateTime(session['checkinAt']) ?? '-',
                ),
                const SizedBox(height: 6),
                _timeRow(
                  Icons.logout_rounded,
                  'Check-out',
                  _formatDateTime(session['checkoutAt']) ?? 'Sesi masih aktif',
                ),
              ],
            ),
          ),

          // ── Payment ─────────────────────────────────────
          if (payment != null) ...[
            _divider(),
            _paymentSection(payment),
          ],

          // ── Dispatches ──────────────────────────────────
          if (dispatches.isNotEmpty) ...[
            _divider(),
            _dispatchSection(dispatches),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _cardHeader(
    Map<String, dynamic> session,
    String status,
    bool isPaid,
  ) {
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'active':
        statusColor = AppColors.active;
        statusLabel = 'Aktif';
        break;
      case 'waiting_for_payment':
        statusColor = AppColors.waiting;
        statusLabel = 'Menunggu Bayar';
        break;
      default:
        statusColor = AppColors.textSub;
        statusLabel = 'Selesai';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDate(session['checkinAt']),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textMain,
            ),
          ),
          Row(
            children: [
              if (!isPaid && status != 'active')
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inactive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Belum Bayar',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inactive,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentSection(Map<String, dynamic> payment) {
    final payStatus = payment['status'] as String? ?? 'pending';
    final amount = payment['amount'];
    final paymentType = payment['paymentType'] as String?;

    Color payColor;
    switch (payStatus) {
      case 'success':
        payColor = AppColors.active;
        break;
      case 'pending':
        payColor = AppColors.waiting;
        break;
      default:
        payColor = AppColors.inactive;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pembayaran',
                  style: TextStyle(fontSize: 11, color: AppColors.textSub),
                ),
                Row(
                  children: [
                    Text(
                      _formatCurrency(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textMain,
                      ),
                    ),
                    if (paymentType != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        paymentType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: payColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _paymentStatusLabel(payStatus),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: payColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dispatchSection(List<Map<String, dynamic>> dispatches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.waiting.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  size: 16,
                  color: AppColors.waiting,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Dispatch (${dispatches.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...dispatches.map(
            (d) => Padding(
              padding: const EdgeInsets.only(left: 38, bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 5,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(d['dispatchedAt']) ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMain,
                    ),
                  ),
                  if (d['dispatchedBy'] != null) ...[
                    const Text(
                      '  •  ',
                      style: TextStyle(color: AppColors.textSub),
                    ),
                    Text(
                      d['dispatchedBy']['name'] ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSub),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSub),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Divider(height: 1, color: AppColors.border),
  );

  // ── Helpers ──────────────────────────────────────────────────────────────

  String? _formatDateTime(dynamic value) {
    if (value == null) return null;
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return DateFormat('dd MMM yyyy', 'id').format(dt);
    } catch (_) {
      return '-';
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

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'success':
        return 'Lunas';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
