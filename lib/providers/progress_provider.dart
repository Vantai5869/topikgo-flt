import 'package:flutter/material.dart';
import '../data/models/progress_data.dart';
import '../data/models/topik_exam.dart';
import '../data/services/auth_service.dart';
import '../data/services/data_service.dart';
import '../data/services/storage_service.dart';
import '../core/constants/instructions.dart';

class ProgressProvider with ChangeNotifier {
  final AuthService _authService;
  final DataService _dataService;
  final StorageService _storageService;

  ProgressData? _progressData;
  Map<String, PracticeHistoryItem> _practiceHistory = {};
  Map<String, PracticeHistoryItem> _pendingSync = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  ProgressProvider(this._authService, this._dataService, this._storageService);

  Future<void> loadPendingSync() async {
    final user = _storageService.getUserData();
    final pendingList = _storageService.getPendingSync(userId: user?.id);
    _pendingSync = {for (var item in pendingList) item.questionId: item};
    notifyListeners();
  }

  ProgressData? get progressData => _progressData;
  bool get isLoading => _isLoading;

  // Get progress for a specific level
  Map<String, dynamic> getLevelProgress(String level) {
    final exams = _dataService.getExamsByLevelAndSkill(level, '듣기') +
        _dataService.getExamsByLevelAndSkill(level, '읽기');

    int totalQuestions = 0;
    int answeredQuestions = 0;
    int correctAnswers = 0;

    for (var exam in exams) {
      for (var group in exam.instructionGroups) {
        for (var question in group.questions) {
          totalQuestions++;
          final uniqueKey = '${exam.id}-${question.id}';
          final history = _practiceHistory[uniqueKey];
          if (history != null) {
            answeredQuestions++;
            if (history.isCorrect) {
              correctAnswers++;
            }
          }
        }
      }
    }

    final progressPercentage = totalQuestions > 0
        ? (answeredQuestions / totalQuestions) * 100
        : 0.0;
    final accuracyPercentage = answeredQuestions > 0
        ? (correctAnswers / answeredQuestions) * 100
        : 0.0;

    // Get skill-specific progress
    final listeningExams = _dataService.getExamsByLevelAndSkill(level, '듣기');
    final readingExams = _dataService.getExamsByLevelAndSkill(level, '읽기');

    final listeningProgress = _calculateSkillProgress(listeningExams);
    final readingProgress = _calculateSkillProgress(readingExams);

    return {
      'progressPercentage': progressPercentage,
      'accuracyPercentage': accuracyPercentage,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'correctAnswers': correctAnswers,
      'skills': {
        '듣기': listeningProgress,
        '읽기': readingProgress,
      },
    };
  }

  // Get progress for a specific instruction (type)
  Map<String, dynamic> getInstructionProgress(String level, String skill, String instruction) {
    final range = Instructions.extractRange(instruction);
    if (range == null) return {'answered': 0, 'total': 0};

    final start = range['start']!;
    final end = range['end']!;
    
    final exams = _dataService.getExamsByLevelAndSkill(level, skill);
    final total = (end - start + 1) * exams.length;

    int answered = 0;
    
    // We need to check all exams for this level/skill and count questions in this range that are answered
    for (var exam in exams) {
      for (var group in exam.instructionGroups) {
        for (var question in group.questions) {
          if (question.number >= start && question.number <= end) {
            final uniqueKey = '${exam.id}-${question.id}';
            if (_practiceHistory.containsKey(uniqueKey)) {
              answered++;
            }
          }
        }
      }
    }

    return {
      'answered': answered,
      'total': total,
      'percentage': total > 0 ? (answered / total) * 100 : 0.0,
    };
  }

  Map<String, dynamic> _calculateSkillProgress(List<TOPIKExam> exams) {
    int totalQuestions = 0;
    int answeredQuestions = 0;
    int correctAnswers = 0;

    for (var exam in exams) {
      for (var group in exam.instructionGroups) {
        for (var question in group.questions) {
          totalQuestions++;
          final uniqueKey = '${exam.id}-${question.id}';
          final history = _practiceHistory[uniqueKey];
          if (history != null) {
            answeredQuestions++;
            if (history.isCorrect) {
              correctAnswers++;
            }
          }
        }
      }
    }

    final progressPercentage = totalQuestions > 0
        ? (answeredQuestions / totalQuestions) * 100
        : 0.0;
    final accuracyPercentage = answeredQuestions > 0
        ? (correctAnswers / answeredQuestions) * 100
        : 0.0;

    return {
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'correctAnswers': correctAnswers,
      'progressPercentage': progressPercentage,
      'accuracyPercentage': accuracyPercentage,
    };
  }

  // Load progress from API
  Future<void> loadProgress(String? token, {bool force = false}) async {
    if (token == null) {
      _progressData = null;
      _practiceHistory = {};
      _isInitialized = false;
      notifyListeners();
      return;
    }

    if (_isInitialized && !force) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load pending from local storage first
      await loadPendingSync();

      // 2. Sync pending data if any before loading new data
      if (_pendingSync.isNotEmpty) {
        await syncPendingProgress(token);
      }

      // 2. Load practice history from server
      final history = await _authService.getPracticeHistory(token);
      _practiceHistory = {
        for (var item in history) item.questionId: item
      };

      // 3. Load progress stats
      _progressData = await _authService.getProgressStats();
    } catch (e) {
      print('Error loading progress: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save practice answer - Cache First & Background Sync
  Future<void> savePracticeAnswer({
    String? token,
    required String examId,
    required String questionId,
    required int answer,
    required bool isCorrect,
  }) async {
    final uniqueKey = '$examId-$questionId';
    
    final item = PracticeHistoryItem(
      questionId: uniqueKey,
      answer: answer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
    );

    // 1. Update local state immediately (Cache)
    final user = _storageService.getUserData();
    _practiceHistory[uniqueKey] = item;
    _pendingSync[uniqueKey] = item;
    await _storageService.savePendingSync(_pendingSync.values.toList(), userId: user?.id);
    notifyListeners();

    // 2. Save to API in background (Non-blocking)
    if (token != null) {
      _authService.savePracticeHistory(
        token: token,
        questionId: uniqueKey,
        answer: answer,
        isCorrect: isCorrect,
      ).then((_) async {
        // Success: Remove from pending
        _pendingSync.remove(uniqueKey);
        await _storageService.savePendingSync(_pendingSync.values.toList(), userId: user?.id);
      }).catchError((e) {
        print('Background sync error: $e');
        // Keep in pending for later sync (logout or next app start)
      });
    }
  }

  // Sync all pending data to server
  Future<void> syncPendingProgress(String token) async {
    if (_pendingSync.isEmpty) return;

    final itemsToSync = Map<String, PracticeHistoryItem>.from(_pendingSync);
    final user = _storageService.getUserData();
    
    for (var entry in itemsToSync.entries) {
      try {
        await _authService.savePracticeHistory(
          token: token,
          questionId: entry.key,
          answer: entry.value.answer,
          isCorrect: entry.value.isCorrect,
        );
        _pendingSync.remove(entry.key);
      } catch (e) {
        print('Error syncing item ${entry.key}: $e');
      }
    }
    
    await _storageService.savePendingSync(_pendingSync.values.toList(), userId: user?.id);
    notifyListeners();
  }

  // Check if question has been answered
  bool isQuestionAnswered(String questionId) {
    return _practiceHistory.containsKey(questionId);
  }

  // Get answer for a question
  PracticeHistoryItem? getQuestionHistory(String questionId) {
    return _practiceHistory[questionId];
  }

  // Clear progress (for logout)
  void clearProgress() {
    _progressData = null;
    _practiceHistory = {};
    notifyListeners();
  }
}
