import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:cico_project/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService sebagai singleton — satu instance Dio untuk semua controller
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
