import 'package:cico_project/auth/bindings/login_binding.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth/views/login_screen.dart';

void main() {
  runApp(const CicoApp());
}

class CicoApp extends StatelessWidget {
  const CicoApp({super.key});

  @override
  Widget build(BuildContext context) {
  return GetMaterialApp(
      title: 'CICO Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      initialBinding: LoginBinding(),
    );
  }
}