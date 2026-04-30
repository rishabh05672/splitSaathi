import 'package:intl/intl.dart';

/// Date formatting and relative time helpers.
class DateHelper {
  DateHelper._();

  /// Formats a DateTime to a relative time string.
  /// e.g., "Just now", "2 mins ago", "1 hour ago", "Yesterday", "Apr 28"
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return DateFormat('MMM d').format(dateTime);
  }

  /// Returns "Today", "Yesterday", or a formatted date string for grouping.
  static String groupLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Formats a DateTime to "Apr 2025" style for month displays.
  static String monthYear(DateTime dateTime) {
    return DateFormat('MMMM yyyy').format(dateTime);
  }

  /// Formats a DateTime to "YYYY-MM" for Firestore settlement keys.
  static String settlementKey(DateTime dateTime) {
    return DateFormat('yyyy-MM').format(dateTime);
  }

  /// Formats a DateTime for display: "Apr 28, 2025 at 3:30 PM"
  static String fullDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime);
  }

  /// Formats a DateTime to just time: "3:30 PM"
  static String timeOnly(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats a DateTime to "Member since April 2025"
  static String memberSince(DateTime dateTime) {
    return DateFormat('MMMM yyyy').format(dateTime);
  }

  /// Converts a settlement key like "2025-04" to "April 2025".
  static String settlementLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Returns the current month/year as settlement key: "2025-04"
  static String get currentSettlementKey => settlementKey(DateTime.now());
}
