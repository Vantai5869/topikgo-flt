class ExamSession {
  final String id;
  final String examId;
  final ExamMeta examMeta;
  final Map<int, int> selectedAnswers; // questionNumber -> optionIndex
  final int score;
  final int totalQuestions;
  final bool isSubmitted;
  final DateTime submittedAt;
  final int initialDuration; // in seconds
  final String userId;

  ExamSession({
    required this.id,
    required this.examId,
    required this.examMeta,
    required this.selectedAnswers,
    required this.score,
    required this.totalQuestions,
    required this.isSubmitted,
    required this.submittedAt,
    required this.initialDuration,
    required this.userId,
  });

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    // Parse selectedAnswers from Map<String, dynamic> to Map<int, int>
    final Map<int, int> answers = {};
    if (json['selectedAnswers'] != null) {
      (json['selectedAnswers'] as Map<String, dynamic>).forEach((key, value) {
        answers[int.parse(key)] = value as int;
      });
    }

    return ExamSession(
      id: json['_id'] ?? json['id'] ?? '',
      examId: json['examId']?.toString() ?? '',
      examMeta: ExamMeta.fromJson(json['examMeta'] ?? {}),
      selectedAnswers: answers,
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      isSubmitted: json['isSubmitted'] ?? false,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      initialDuration: json['initialDuration'] ?? 0,
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // Convert Map<int, int> to Map<String, int> for JSON
    final Map<String, int> answersJson = {};
    selectedAnswers.forEach((key, value) {
      answersJson[key.toString()] = value;
    });

    return {
      if (id.isNotEmpty) '_id': id,
      'examId': examId,
      'examMeta': examMeta.toJson(),
      'selectedAnswers': answersJson,
      'score': score,
      'totalQuestions': totalQuestions,
      'isSubmitted': isSubmitted,
      'submittedAt': submittedAt.toIso8601String(),
      'initialDuration': initialDuration,
      if (userId.isNotEmpty) 'userId': userId,
    };
  }

  // Calculate percentage
  double get percentage {
    if (totalQuestions == 0) return 0;
    return (score / totalQuestions) * 100;
  }
}

class ExamMeta {
  final String? description;
  final String? level;
  final String? skill;
  final String? year;

  ExamMeta({
    this.description,
    this.level,
    this.skill,
    this.year,
  });

  factory ExamMeta.fromJson(Map<String, dynamic> json) {
    return ExamMeta(
      description: json['description'],
      level: json['level'],
      skill: json['skill'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (description != null) 'description': description,
      if (level != null) 'level': level,
      if (skill != null) 'skill': skill,
      if (year != null) 'year': year,
    };
  }
}

class ExamSessionsResponse {
  final List<ExamSession> sessions;
  final int currentPage;
  final int totalPages;
  final int totalSessions;

  ExamSessionsResponse({
    required this.sessions,
    required this.currentPage,
    required this.totalPages,
    required this.totalSessions,
  });

  factory ExamSessionsResponse.fromJson(Map<String, dynamic> json) {
    return ExamSessionsResponse(
      sessions: (json['sessions'] as List?)
              ?.map((e) => ExamSession.fromJson(e))
              .toList() ??
          [],
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
    );
  }
}
