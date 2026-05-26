import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends GetView<HistoryController> {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
              onPressed: controller.loadAll,
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSub,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: [
              Tab(text: 'Check-in'),
              Tab(text: 'Pembayaran'),
              Tab(text: 'Dispatch'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCheckinTab(),
            _buildPaymentTab(),
            _buildDispatchTab(),
          ],
        ),
      ),
    );
  }

  // ── CHECK-IN TAB ──────────────────────────────────────────────────────────

  Widget _buildCheckinTab() {
    return Obx(() {
      if (controller.isLoadingCheckin.value) return _loading();
      if (controller.checkinList.isEmpty) return _empty('Belum ada riwayat check-in');
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadCheckinHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.checkinList.length,
          itemBuilder: (_, i) => _checkinCard(controller.checkinList[i]),
        ),
      );
    });
  }

  Widget _checkinCard(Map<String, dynamic> item) {
    final checkinAt = _formatDateTime(item['checkinAt']);
    final checkoutAt = _formatDateTime(item['checkoutAt']);
    final isPaid = item['isPaid'] == true;
    final payment = item['payment'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(item['checkinAt']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textMain,
                ),
              ),
              _badge(
                isPaid ? 'Lunas' : 'Belum Bayar',
                isPaid ? AppColors.active : AppColors.waiting,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _timeRow(Icons.login_rounded, 'Check-in', checkinAt ?? '-'),
          const SizedBox(height: 6),
          _timeRow(
            Icons.logout_rounded,
            'Check-out',
            checkoutAt ?? 'Sesi masih aktif',
          ),
          if (payment != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payment_rounded, size: 14, color: AppColors.textSub),
                const SizedBox(width: 6),
                Text(
                  _formatCurrency(payment['amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 8),
                if (payment['paymentType'] != null)
                  Text(
                    (payment['paymentType'] as String).toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── PAYMENT TAB ───────────────────────────────────────────────────────────

  Widget _buildPaymentTab() {
    return Obx(() {
      if (controller.isLoadingPayment.value) return _loading();
      if (controller.paymentList.isEmpty) return _empty('Belum ada riwayat pembayaran');
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadPaymentHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.paymentList.length,
          itemBuilder: (_, i) => _paymentCard(controller.paymentList[i]),
        ),
      );
    });
  }

  Widget _paymentCard(Map<String, dynamic> item) {
    final status = item['status'] as String? ?? 'pending';
    final amount = item['amount'];
    final paymentType = item['paymentType'] as String?;
    final paidAt = _formatDateTime(item['paidAt']);
    final createdAt = _formatDateTime(item['createdAt']);
    final orderId = item['midtransOrderId'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _paymentStatusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              if (paymentType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (paidAt != null)
            _timeRow(Icons.check_circle_outline_rounded, 'Dibayar', paidAt)
          else
            _timeRow(Icons.access_time_rounded, 'Dibuat', createdAt ?? '-'),
        ],
      ),
    );
  }

  // ── DISPATCH TAB ──────────────────────────────────────────────────────────

  Widget _buildDispatchTab() {
    return Obx(() {
      if (controller.isLoadingDispatch.value) return _loading();
      if (controller.dispatchList.isEmpty) return _empty('Belum ada riwayat dispatch');
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadDispatchHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.dispatchList.length,
          itemBuilder: (_, i) => _dispatchCard(controller.dispatchList[i]),
        ),
      );
    });
  }

  Widget _dispatchCard(Map<String, dynamic> item) {
    final dispatchedAt = _formatDateTime(item['dispatchedAt']);
    final dispatchedBy = item['dispatchedBy'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dispatchedAt ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dispatchedBy != null
                      ? 'Oleh: ${dispatchedBy['name'] ?? 'Admin'}'
                      : 'Admin tidak diketahui',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _loading() {
    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _empty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: AppColors.textSub.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textSub, fontSize: 14)),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _paymentStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'success':
        color = AppColors.active;
        label = 'Sukses';
        break;
      case 'pending':
        color = AppColors.waiting;
        label = 'Pending';
        break;
      case 'failed':
        color = AppColors.inactive;
        label = 'Gagal';
        break;
      case 'expired':
        color = AppColors.textSub;
        label = 'Expired';
        break;
      case 'cancelled':
        color = AppColors.textSub;
        label = 'Dibatalkan';
        break;
      default:
        color = AppColors.textSub;
        label = status;
    }
    return _badge(label, color);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

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
}
