import 'dart:io';
import 'dart:math';
import '../../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/exam_session.dart';
import '../models/progress_data.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  // Get platform
  String _getPlatform() {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'WEB';
  }

  // Generate verification code (4 digits)
  String generateVerificationCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // Send verification code
  Future<bool> sendVerificationCode(String email, String code) async {
    try {
      final response = await _apiService.post(
        ApiConstants.sendMail,
        data: {
          'email': email,
          'code': code,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Gửi mã xác nhận thất bại: ${e.toString()}');
    }
  }

  // Verify and login
  Future<AuthResponse> verifyAndLogin(String email, String deviceId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.users,
        data: {
          'email': email,
          'deviceId': deviceId,
          'platform': _getPlatform(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data);
        
        // Save auth data
        await _storageService.saveAuthToken(authResponse.token);
        await _storageService.saveUserData(authResponse.user);
        
        return authResponse;
      } else {
        throw Exception('Xác thực hoặc đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  // Get stored auth data
  Future<({User? user, String? token})> getStoredAuth() async {
    final user = _storageService.getUserData();
    final token = _storageService.getAuthToken();
    return (user: user, token: token);
  }

  // Clear auth data
  Future<void> clearAuth() async {
    await _storageService.clearAuthData();
  }

  // Get practice history from API
  Future<List<PracticeHistoryItem>> getPracticeHistory(String token) async {
    try {
      final response = await _apiService.get(ApiConstants.practiceHistory);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        // API returns { history: [...] } or just array
        if (data is Map && data['history'] is List) {
          return (data['history'] as List)
              .map((e) => PracticeHistoryItem.fromJson(e))
              .toList();
        } else if (data is List) {
          return data.map((e) => PracticeHistoryItem.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Save practice history to API
  Future<void> savePracticeHistory({
    required String token,
    required String questionId,
    required int answer,
    required bool isCorrect,
  }) async {
    try {
      await _apiService.post(
        ApiConstants.practiceHistory,
        data: {
          'questionId': questionId,
          'answer': answer,
          'isCorrect': isCorrect,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Don't throw error - we'll still update local state
    }
  }

  // Submit exam session
  Future<void> submitExamSession({
    required String token,
    required ExamSession sessionData,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConstants.examSessions,
        data: sessionData.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Lưu kết quả bài thi thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get exam sessions
  Future<ExamSessionsResponse> getExamSessions({
    String? examId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (examId != null) 'examId': examId,
      };

      final response = await _apiService.get(
        ApiConstants.examSessions,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ExamSessionsResponse.fromJson(response.data);
      }

      return ExamSessionsResponse(
        sessions: [],
        currentPage: page,
        totalPages: 0,
        totalSessions: 0,
      );
    } catch (e) {
      return ExamSessionsResponse(
        sessions: [],
        currentPage: page,
        totalPages: 0,
        totalSessions: 0,
      );
    }
  }

  // Get exam session by ID
  Future<ExamSession?> getExamSessionById(String sessionId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.examSessions}/$sessionId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ExamSession.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get progress stats
  Future<ProgressData?> getProgressStats() async {
    try {
      final response = await _apiService.get(ApiConstants.progressStats);

      if (response.statusCode == 200 && response.data != null) {
        return ProgressData.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // YouTube Saved Videos API
  Future<List<Map<String, dynamic>>> getSavedVideos() async {
    try {
      final response = await _apiService.get(ApiConstants.savedVideos);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['videos'] is List) {
          final videos = List<Map<String, dynamic>>.from(data['videos']);
          return videos;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> saveVideo(Map<String, dynamic> videoData) async {
    try {
      final response = await _apiService.post(
        ApiConstants.savedVideos,
        data: videoData,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> syncVideos(List<Map<String, dynamic>> videos) async {
    try {
      await _apiService.post(
        ApiConstants.syncVideos,
        data: {'videos': videos},
      );
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }
}
