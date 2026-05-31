import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand — deep teal / transport ──────────────────────────────────────────
  static const Color primary = Color(0xFF0E9AA3);
  static const Color brand600 = Color(0xFF0B7E87);
  static const Color brand700 = Color(0xFF0A626B);
  static const Color panelInk = Color(0xFF0C262E);   // dark teal-charcoal stage
  static const Color panelInk2 = Color(0xFF123640);
  static const Color brandTint = Color(0xFFDFF1F2);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFEAF0F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF2F6F7);
  static const Color ink = Color(0xFF0B1F26);
  static const Color ink2 = Color(0xFF41555E);
  static const Color muted = Color(0xFF7A8C93);
  static const Color line = Color(0xFFE4EBEC);
  static const Color lineSoft = Color(0xFFEEF3F4);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color ok = Color(0xFF11A56B);
  static const Color okTint = Color(0xFFE2F6EE);
  static const Color danger = Color(0xFFF0463C);
  static const Color dangerTint = Color(0xFFFDEBE9);
  static const Color warn = Color(0xFFF5921B);
  static const Color warnTint = Color(0xFFFEF0DE);
  static const Color info = Color(0xFF2C6BF0);
  static const Color infoTint = Color(0xFFE7EEFE);

  // ── Legacy aliases (used across controllers / notifiers) ──────────────────
  static const Color active = ok;
  static const Color standby = info;
  static const Color waiting = warn;
  static const Color inactive = danger;
  static const Color textMain = ink;
  static const Color textSub = muted;
  static const Color border = line;
}
