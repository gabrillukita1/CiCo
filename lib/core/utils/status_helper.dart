import 'package:flutter/material.dart';
import 'package:cico_project/core/style/app_colors.dart';

class DriverStatusInfo {
  final Color color;
  final IconData icon;
  final String label;
  final String displayText;

  const DriverStatusInfo({
    required this.color,
    required this.icon,
    required this.label,
    required this.displayText,
  });
}

class StatusHelper {
  StatusHelper._();

  /// Status driver aktif (HomeScreen, ProfileScreen)
  static DriverStatusInfo of(String status) {
    switch (status) {
      case 'on_duty':
        return const DriverStatusInfo(
          color: AppColors.ok,
          icon: Icons.directions_car_rounded,
          label: 'On Duty',
          displayText: 'ON DUTY',
        );
      case 'standby':
        return const DriverStatusInfo(
          color: AppColors.info,
          icon: Icons.access_time_rounded,
          label: 'Standby',
          displayText: 'STANDBY',
        );
      case 'pending_payment':
        return const DriverStatusInfo(
          color: AppColors.warn,
          icon: Icons.payment_rounded,
          label: 'Pending Payment',
          displayText: 'PENDING PAYMENT',
        );
      case 'offline':
      default:
        return const DriverStatusInfo(
          color: AppColors.danger,
          icon: Icons.power_settings_new_rounded,
          label: 'Offline',
          displayText: 'OFFLINE',
        );
    }
  }

  /// Status sesi di History
  static DriverStatusInfo ofSession(String status) {
    switch (status) {
      case 'active':
        return const DriverStatusInfo(
          color: AppColors.ok,
          icon: Icons.radio_button_checked_rounded,
          label: 'Active',
          displayText: 'ACTIVE',
        );
      case 'completed':
        return const DriverStatusInfo(
          color: AppColors.brand600,
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          displayText: 'COMPLETED',
        );
      case 'expired':
        return const DriverStatusInfo(
          color: AppColors.muted,
          icon: Icons.cancel_outlined,
          label: 'Expired',
          displayText: 'EXPIRED',
        );
      default:
        return of(status);
    }
  }
}
