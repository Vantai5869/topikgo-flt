import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/device_id_generator.dart';
import '../models/progress_data.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Auth Token
  Future<void> saveAuthToken(String token) async {
    await _prefs!.setString(ApiConstants.authTokenKey, token);
  }

  String? getAuthToken() {
    return _prefs!.getString(ApiConstants.authTokenKey);
  }

  Future<void> removeAuthToken() async {
    await _prefs!.remove(ApiConstants.authTokenKey);
  }

  // User Data
  Future<void> saveUserData(User user) async {
    await _prefs!.setString(ApiConstants.userDataKey, json.encode(user.toJson()));
  }

  User? getUserData() {
    final userDataStr = _prefs!.getString(ApiConstants.userDataKey);
    if (userDataStr == null) return null;
    try {
      return User.fromJson(json.decode(userDataStr));
    } catch (e) {
      return null;
    }
  }

  Future<void> removeUserData() async {
    await _prefs!.remove(ApiConstants.userDataKey);
  }

  // Device ID
  Future<String> getOrGenerateDeviceId() async {
    String? deviceId = _prefs!.getString(ApiConstants.deviceIdKey);
    if (deviceId == null) {
      deviceId = DeviceIdGenerator.generate();
      await _prefs!.setString(ApiConstants.deviceIdKey, deviceId);
    }
    return deviceId;
  }

  // Theme Mode
  Future<void> saveThemeMode(bool isDark) async {
    await _prefs!.setBool(ApiConstants.themeKey, isDark);
  }

  bool? getThemeMode() {
    return _prefs!.getBool(ApiConstants.themeKey);
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      removeAuthToken(),
      removeUserData(),
    ]);
  }

  // Generic methods
  Future<void> setString(String key, String value) async {
    await _prefs!.setString(key, value);
  }

  String? getString(String key) {
    return _prefs!.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs!.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs!.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs!.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs!.remove(key);
  }

  Future<void> clear() async {
    await _prefs!.clear();
  }

  // Pending Sync Practice History
  static const String _pendingSyncKeyPrefix = 'pending_sync_practice_';

  Future<void> savePendingSync(List<PracticeHistoryItem> items, {String? userId}) async {
    final key = '$_pendingSyncKeyPrefix${userId ?? 'guest'}';
    final data = items.map((e) => e.toJson()).toList();
    await _prefs!.setString(key, json.encode(data));
  }

  List<PracticeHistoryItem> getPendingSync({String? userId}) {
    final key = '$_pendingSyncKeyPrefix${userId ?? 'guest'}';
    final dataStr = _prefs!.getString(key);
    if (dataStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(dataStr);
      return decoded.map((e) => PracticeHistoryItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPendingSync({String? userId}) async {
    final key = '$_pendingSyncKeyPrefix${userId ?? 'guest'}';
    await _prefs!.remove(key);
  }

  // YouTube Practice History
  static const String _youtubeHistoryKey = 'youtube_practice_history';

  Future<void> saveYouTubeHistory(List<Map<String, String>> history, {String? userId}) async {
    final key = userId != null ? '${_youtubeHistoryKey}_$userId' : _youtubeHistoryKey;
    await _prefs!.setString(key, json.encode(history));
  }

  List<Map<String, String>> getYouTubeHistory({String? userId}) {
    final key = userId != null ? '${_youtubeHistoryKey}_$userId' : _youtubeHistoryKey;
    final dataStr = _prefs!.getString(key);
    if (dataStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(dataStr);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
