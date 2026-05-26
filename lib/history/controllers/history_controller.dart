import 'package:cico_project/auth/services/auth_service.dart';
import 'package:get/get.dart';

class HistoryController extends GetxController {
  final _authService = AuthService();

  final checkinList = <Map<String, dynamic>>[].obs;
  final paymentList = <Map<String, dynamic>>[].obs;
  final dispatchList = <Map<String, dynamic>>[].obs;

  final isLoadingCheckin = true.obs;
  final isLoadingPayment = true.obs;
  final isLoadingDispatch = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadCheckinHistory(),
      loadPaymentHistory(),
      loadDispatchHistory(),
    ]);
  }

  Future<void> loadCheckinHistory() async {
    isLoadingCheckin.value = true;
    final res = await _authService.getCheckinHistory();
    if (res != null) {
      final data = res['data'] as List? ?? [];
      checkinList.value = data.cast<Map<String, dynamic>>();
    }
    isLoadingCheckin.value = false;
  }

  Future<void> loadPaymentHistory() async {
    isLoadingPayment.value = true;
    final res = await _authService.getPaymentHistory();
    if (res != null) {
      final data = res['data'] as List? ?? [];
      paymentList.value = data.cast<Map<String, dynamic>>();
    }
    isLoadingPayment.value = false;
  }

  Future<void> loadDispatchHistory() async {
    isLoadingDispatch.value = true;
    final res = await _authService.getDispatchHistory();
    if (res != null) {
      final data = res['data'] as List? ?? [];
      dispatchList.value = data.cast<Map<String, dynamic>>();
    }
    isLoadingDispatch.value = false;
  }
}
