import 'package:flutter/material.dart';
import '../data/services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  final StorageService _storageService;

  ThemeProvider(this._storageService) {
    _loadTheme();
  }

  bool get isDark => _isDark;

  Future<void> _loadTheme() async {
    final savedTheme = _storageService.getThemeMode();
    if (savedTheme != null) {
      _isDark = savedTheme;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _storageService.saveThemeMode(_isDark);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDark = isDark;
    await _storageService.saveThemeMode(_isDark);
    notifyListeners();
  }
}
