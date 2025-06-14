import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateTimeHelper {
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat(AppConstants.dateFormat).format(dateTime);
  }

  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1
          ? ''
          : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1
          ? ''
          : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime? date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isTomorrow(DateTime? date) {
    if (date == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  static bool isYesterday(DateTime? date) {
    if (date == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
}

class NumberHelper {
  static String formatCurrency(double? amount, {String currency = 'OMR'}) {
    if (amount == null) return '$currency 0.000';
    return '$currency ${amount.toStringAsFixed(3)}';
  }

  static String formatRating(double? rating) {
    if (rating == null) return '0.0';
    return rating.toStringAsFixed(1);
  }

  static String formatPercentage(double? value) {
    if (value == null) return '0%';
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}

class StringHelper {
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ')
        .map((word) => capitalize(word))
        .join(' ');
  }

  static String truncate(String? text, int maxLength) {
    if (text == null || text.length <= maxLength) return text ?? '';
    return '${text.substring(0, maxLength)}...';
  }

  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return '';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }
}