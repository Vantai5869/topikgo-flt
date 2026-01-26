class AppConstants {
  // App Info
  static const String appName = 'TOPIK GO';
  static const String appVersion = '1.0.1';
  
  // TOPIK Levels
  static const String topikI = 'TOPIK Ⅰ';
  static const String topikII = 'TOPIK Ⅱ';
  
  // Skills
  static const String listening = '듣기';
  static const String reading = '읽기';
  
  // Platform
  static String getPlatform() {
    // Will be determined at runtime
    return 'iOS'; // Default, will be updated based on Platform.isIOS/isAndroid
  }
}
