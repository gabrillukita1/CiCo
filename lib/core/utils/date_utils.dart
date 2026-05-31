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

String formatDateRange(dynamic checkin, dynamic checkout, {String fallback = ''}) {
  final ci = toJakarta(checkin);
  if (ci == null) return fallback;
  final co = toJakarta(checkout);
  if (co == null) return DateFormat('d MMM yyyy').format(ci);

  final sameDay = ci.year == co.year && ci.month == co.month && ci.day == co.day;
  if (sameDay) return DateFormat('d MMM yyyy').format(ci);

  final sameMonth = ci.year == co.year && ci.month == co.month;
  if (sameMonth) return '${ci.day} - ${DateFormat('d MMM yyyy').format(co)}';

  final sameYear = ci.year == co.year;
  if (sameYear) return '${DateFormat('d MMM').format(ci)} - ${DateFormat('d MMM yyyy').format(co)}';

  return '${DateFormat('d MMM yyyy').format(ci)} - ${DateFormat('d MMM yyyy').format(co)}';
}
