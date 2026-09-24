/// Normalizes timestamp values crossing the Drift/Supabase boundary.
abstract final class SyncTimestamp {
  static DateTime? parse(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is int) {
      // SQLite/Drift raw values can be epoch seconds or milliseconds. DIMI
      // dates are modern, so values below this boundary are seconds.
      final milliseconds = value.abs() < 100000000000
          ? value * 1000
          : value;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static String? toUtcIso8601(Object? value) => parse(value)?.toIso8601String();

  static String? toCalendarDate(Object? value) {
    final date = value is DateTime ? value : parse(value);
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
