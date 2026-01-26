import 'package:intl/intl.dart';

class DateFormatter {
  /// Format date to ISO 8601 string
  static String toIso8601(DateTime date) {
    return date.toIso8601String();
  }
  
  /// Parse ISO 8601 string to DateTime
  static DateTime? fromIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Format date to readable string (e.g., "25/12/2025")
  static String toReadable(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  /// Format date with time (e.g., "25/12/2025 11:30")
  static String toReadableWithTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  /// Format time only (e.g., "11:30")
  static String toTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
