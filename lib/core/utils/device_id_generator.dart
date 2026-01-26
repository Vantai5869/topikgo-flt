import 'dart:math';
import 'package:uuid/uuid.dart';

class DeviceIdGenerator {
  static const _uuid = Uuid();
  
  /// Generate a device ID similar to React Native version
  /// Format: timestamp_randomString
  static String generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _generateRandomString(13);
    return '${timestamp}_$random';
  }
  
  /// Generate random alphanumeric string
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Generate UUID v4
  static String generateUuid() {
    return _uuid.v4();
  }
}
