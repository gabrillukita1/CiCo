import 'package:cico_project/app/routes/app_routes.dart';
import 'package:cico_project/home/views/home_screen.dart';
import 'package:get/get.dart';
import '../../auth/bindings/login_binding.dart';
import '../../auth/views/login_screen.dart';
import '../../home/bindings/home_binding.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}