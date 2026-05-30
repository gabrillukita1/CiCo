import 'package:flutter/material.dart';
import 'package:cico_project/core/style/app_colors.dart';

class DriverStatusInfo {
  final Color color;
  final IconData icon;
  final String label;       // singkat, untuk badge
  final String displayText; // UPPERCASE, untuk status visual besar

  const DriverStatusInfo({
    required this.color,
    required this.icon,
    required this.label,
    required this.displayText,
  });
}

class StatusHelper {
  StatusHelper._();

  static DriverStatusInfo of(String status) {
    switch (status) {
      case 'on_duty':
        return const DriverStatusInfo(
          color: AppColors.active,
          icon: Icons.check_circle_rounded,
          label: 'Bertugas',
          displayText: 'ON DUTY',
        );
      case 'standby':
        return const DriverStatusInfo(
          color: AppColors.standby,
          icon: Icons.access_time_rounded,
          label: 'Standby',
          displayText: 'STANDBY',
        );
      case 'pending_payment':
        return const DriverStatusInfo(
          color: AppColors.waiting,
          icon: Icons.hourglass_empty_rounded,
          label: 'Menunggu Pembayaran',
          displayText: 'PENDING PAYMENT',
        );
      case 'offline':
      default:
        return const DriverStatusInfo(
          color: AppColors.inactive,
          icon: Icons.cancel_rounded,
          label: 'Offline',
          displayText: 'OFFLINE',
        );
    }
  }
}
