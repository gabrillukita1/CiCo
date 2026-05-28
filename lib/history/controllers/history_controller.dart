import 'package:cico_project/auth/services/auth_service.dart';
import 'package:get/get.dart';

class HistoryController extends GetxController {
  final _authService = AuthService();

  final sessionList = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  int _currentPage = 1;
  static const int _limit = 10;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    _currentPage = 1;
    hasMore.value = true;

    final res = await _authService.getCheckinHistory(page: 1, limit: _limit);
    if (res != null) {
      final data = res['data'] as List? ?? [];
      sessionList.value = data.cast<Map<String, dynamic>>();
      final totalPages = res['totalPages'] as int? ?? 1;
      hasMore.value = _currentPage < totalPages;
    }
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    _currentPage++;

    final res = await _authService.getCheckinHistory(
      page: _currentPage,
      limit: _limit,
    );
    if (res != null) {
      final data = res['data'] as List? ?? [];
      sessionList.addAll(data.cast<Map<String, dynamic>>());
      final totalPages = res['totalPages'] as int? ?? 1;
      hasMore.value = _currentPage < totalPages;
    } else {
      _currentPage--;
    }
    isLoadingMore.value = false;
  }
}
