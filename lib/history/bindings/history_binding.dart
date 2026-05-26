import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:get/get.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryController>(() => HistoryController());
  }
}
