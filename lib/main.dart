import 'package:cico_project/auth/services/auth_service.dart';
import 'package:cico_project/core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Singleton AuthService — satu instance Dio untuk seluruh app lifecycle
  final authService = Get.put<AuthService>(AuthService(), permanent: true);

  // Cek token lokal secara sinkron (tidak butuh network) → app langsung tampil
  // Validasi ke server dilakukan di background oleh HomeController.
  // Kalau token expired, interceptor Dio otomatis redirect ke login.
  final hasToken = authService.getToken() != null;

  runApp(CicoApp(
    initialRoute: hasToken ? AppRoutes.home : AppRoutes.login,
  ));
}

class CicoApp extends StatelessWidget {
  final String initialRoute;
  const CicoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Teal status bar — transparent so stage gradient bleeds through
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return GetMaterialApp(
      title: 'CICO Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.hankenGroteskTextTheme(),
      ),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
