import 'package:cico_project/auth/services/biometric_service.dart';
import 'package:cico_project/history/controllers/history_controller.dart';
import 'package:cico_project/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // AuthService sudah di-register permanent di main.dart — tidak perlu di sini
    Get.put<BiometricService>(BiometricService(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
