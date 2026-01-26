class ProgressData {
  final int totalExamsTaken;
  final double overallAverageScorePercentage;
  final Map<String, double> averageBySkill;
  final Map<String, double> averageByLevel;
  final List<ScoreProgressionItem> scoreProgression;

  ProgressData({
    required this.totalExamsTaken,
    required this.overallAverageScorePercentage,
    required this.averageBySkill,
    required this.averageByLevel,
    required this.scoreProgression,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      totalExamsTaken: json['totalExamsTaken'] ?? 0,
      overallAverageScorePercentage:
          (json['overallAverageScorePercentage'] ?? 0).toDouble(),
      averageBySkill: (json['averageBySkill'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      averageByLevel: (json['averageByLevel'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {},
      scoreProgression: (json['scoreProgression'] as List?)
              ?.map((e) => ScoreProgressionItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalExamsTaken': totalExamsTaken,
      'overallAverageScorePercentage': overallAverageScorePercentage,
      'averageBySkill': averageBySkill,
      'averageByLevel': averageByLevel,
      'scoreProgression': scoreProgression.map((e) => e.toJson()).toList(),
    };
  }
}

class ScoreProgressionItem {
  final DateTime date;
  final String examName;
  final int score;
  final int totalQuestions;
  final double percentage;

  ScoreProgressionItem({
    required this.date,
    required this.examName,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
  });

  factory ScoreProgressionItem.fromJson(Map<String, dynamic> json) {
    return ScoreProgressionItem(
      date: DateTime.parse(json['date']),
      examName: json['examName'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'examName': examName,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
    };
  }
}

class PracticeHistoryItem {
  final String questionId;
  final int answer;
  final bool isCorrect;
  final DateTime timestamp;

  PracticeHistoryItem({
    required this.questionId,
    required this.answer,
    required this.isCorrect,
    required this.timestamp,
  });

  factory PracticeHistoryItem.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryItem(
      questionId: json['questionId'] ?? '',
      answer: json['answer'] ?? 0,
      isCorrect: json['isCorrect'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answer': answer,
      'isCorrect': isCorrect,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
