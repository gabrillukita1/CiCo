import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum DateFilter { all, today, thisWeek, thisMonth, custom }

class HistoryController extends GetxController {
  final _authService = Get.find<AuthService>();

  final sessionList = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  final selectedFilter = DateFilter.all.obs;
  final customStart = Rxn<DateTime>();
  final customEnd = Rxn<DateTime>();

  int _currentPage = 1;
  static const int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  DateTimeRange? get _activeDateRange {
    final now = DateTime.now();
    switch (selectedFilter.value) {
      case DateFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      case DateFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(start.year, start.month, start.day);
        return DateTimeRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );
      case DateFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: start, end: end);
      case DateFilter.custom:
        if (customStart.value != null && customEnd.value != null) {
          return DateTimeRange(
            start: customStart.value!,
            end: customEnd.value!.add(const Duration(days: 1)),
          );
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    _currentPage = 1;
    hasMore.value = true;

    try {
      final range = _activeDateRange;
      final res = await _authService.getCheckinHistory(
        page: 1,
        limit: _limit,
        startDate: range?.start,
        endDate: range?.end,
      );
      if (res != null) {
        final data = res['data'] as List? ?? [];
        sessionList.value = data.cast<Map<String, dynamic>>();
        final totalPages = res['totalPages'] as int? ?? 1;
        hasMore.value = _currentPage < totalPages;
      } else {
        AppNotifier.error('Gagal', 'Tidak dapat memuat riwayat sesi.');
      }
    } catch (e) {
      AppNotifier.error('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    _currentPage++;

    try {
      final range = _activeDateRange;
      final res = await _authService.getCheckinHistory(
        page: _currentPage,
        limit: _limit,
        startDate: range?.start,
        endDate: range?.end,
      );
      if (res != null) {
        final data = res['data'] as List? ?? [];
        sessionList.addAll(data.cast<Map<String, dynamic>>());
        final totalPages = res['totalPages'] as int? ?? 1;
        hasMore.value = _currentPage < totalPages;
      } else {
        _currentPage--;
        AppNotifier.error('Gagal', 'Tidak dapat memuat data selanjutnya.');
      }
    } catch (e) {
      _currentPage--;
      AppNotifier.error('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> setFilter(DateFilter filter, {DateTimeRange? range}) async {
    selectedFilter.value = filter;
    if (filter == DateFilter.custom && range != null) {
      customStart.value = range.start;
      customEnd.value = range.end;
    } else if (filter != DateFilter.custom) {
      customStart.value = null;
      customEnd.value = null;
    }
    await loadHistory();
  }
}
