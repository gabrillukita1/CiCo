import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;

  // Status Colors
  static const Color active = Color(0xFF10B981);   // Emerald Green  — on_duty / check-in
  static const Color standby = Color(0xFF3B82F6);  // Blue           — standby
  static const Color waiting = Color(0xFFF59E0B);  // Amber Orange   — pending_payment
  static const Color inactive = Color(0xFFEF4444); // Soft Red       — offline / error

  // Text Colors
  static const Color textMain = Color(0xFF1E293B);
  static const Color textSub = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}