import 'package:cico_project/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  await GetStorage.init();

  final authService = AuthService();
  final isValid = await authService.isTokenValid();

  runApp(CicoApp(
    initialRoute: isValid ? AppRoutes.home : AppRoutes.login,
  ));
}

class CicoApp extends StatelessWidget {
  final String initialRoute;
  const CicoApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CICO Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber, useMaterial3: true),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
