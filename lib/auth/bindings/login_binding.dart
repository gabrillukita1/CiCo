import 'package:cico_project/auth/services/auth_service.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.lazyPut<LoginController>(() => LoginController());
  }
}