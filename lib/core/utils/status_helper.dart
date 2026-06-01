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
          label: 'status_on_duty',
          displayText: 'status_on_duty',
        );
      case 'standby':
        return const DriverStatusInfo(
          color: AppColors.info,
          icon: Icons.access_time_rounded,
          label: 'status_standby',
          displayText: 'status_standby',
        );
      case 'pending_payment':
        return const DriverStatusInfo(
          color: AppColors.warn,
          icon: Icons.payment_rounded,
          label: 'status_pending_payment',
          displayText: 'status_pending_payment',
        );
      case 'offline':
      default:
        return const DriverStatusInfo(
          color: AppColors.danger,
          icon: Icons.power_settings_new_rounded,
          label: 'status_offline',
          displayText: 'status_offline',
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
          label: 'status_active',
          displayText: 'status_active',
        );
      case 'completed':
        return const DriverStatusInfo(
          color: AppColors.brand600,
          icon: Icons.check_circle_rounded,
          label: 'status_completed',
          displayText: 'status_completed',
        );
      case 'expired':
        return const DriverStatusInfo(
          color: AppColors.muted,
          icon: Icons.cancel_outlined,
          label: 'status_expired',
          displayText: 'status_expired',
        );
      default:
        return of(status);
    }
  }
}
