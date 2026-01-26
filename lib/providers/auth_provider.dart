import 'package:flutter/material.dart';
import '../data/models/user.dart';
import '../data/services/auth_service.dart';
import '../data/services/storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  User? _currentUser;
  String? _token;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthProvider(this._authService, this._storageService) {
    _initAuth();
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> _initAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final authData = await _authService.getStoredAuth();
    if (authData.user != null && authData.token != null) {
      _currentUser = authData.user;
      _token = authData.token;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendVerificationCode(String email) async {
    try {
      _errorMessage = null;
      final code = _authService.generateVerificationCode();
      await _authService.sendVerificationCode(email, code);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyAndLogin(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final deviceId = await _storageService.getOrGenerateDeviceId();
      final authResponse = await _authService.verifyAndLogin(email, deviceId);

      _currentUser = authResponse.user;
      _token = authResponse.token;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearAuth();
    _currentUser = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
