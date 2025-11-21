import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  static String formatDateShort(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MM/dd/yyyy').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('hh:mm a').format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return 'Not set';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }
}

