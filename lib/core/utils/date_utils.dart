import 'package:intl/intl.dart';

/// Semua konversi waktu di app ini pakai WIB (UTC+7 / Asia/Jakarta)
const _jakartaOffset = Duration(hours: 7);

DateTime? toJakarta(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString()).toUtc().add(_jakartaOffset);
  } catch (_) {
    return null;
  }
}

String formatDateTime(dynamic value) {
  final dt = toJakarta(value);
  if (dt == null) return '-';
  return DateFormat('dd MMM yyyy, HH:mm').format(dt);
}

String formatTime(dynamic value, {String fallback = '--:--'}) {
  final dt = toJakarta(value);
  if (dt == null) return fallback;
  return DateFormat('HH:mm').format(dt);
}

String formatDate(dynamic value, {String fallback = ''}) {
  final dt = toJakarta(value);
  if (dt == null) return fallback;
  return DateFormat('dd MMM yyyy').format(dt);
}

String formatFullDate(dynamic value, {String fallback = '—'}) {
  final dt = toJakarta(value);
  if (dt == null) return fallback;
  return DateFormat('EEE, dd MMM yyyy').format(dt);
}
