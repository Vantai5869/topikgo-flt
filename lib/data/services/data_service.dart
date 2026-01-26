import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/topik_exam.dart';

class DataService {
  static DataService? _instance;
  List<TOPIKExam> _exams = [];
  bool _isLoaded = false;

  DataService._();

  static DataService getInstance() {
    _instance ??= DataService._();
    return _instance!;
  }

  // Load data from JSON file
  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      _exams = jsonData.map((e) => TOPIKExam.fromJson(e)).toList();
      _isLoaded = true;
      print('Loaded ${_exams.length} exams');
    } catch (e) {
      print('Error loading data: $e');
      _exams = [];
    }
  }

  // Get all exams
  List<TOPIKExam> getAllExams() {
    return _exams;
  }

  // Get exams by level and skill
  List<TOPIKExam> getExamsByLevelAndSkill(String level, String skill) {
    return _exams.where((exam) => exam.level == level && exam.skill == skill).toList();
  }

  // Get exam by ID
  TOPIKExam? getExamById(String id) {
    try {
      return _exams.firstWhere((exam) => exam.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter exams
  List<TOPIKExam> filterExams({
    String? level,
    String? skill,
    String? year,
    String? examNumber,
  }) {
    var filteredExams = _exams;

    if (level != null) {
      filteredExams = filteredExams.where((exam) => exam.level == level).toList();
    }

    if (skill != null) {
      filteredExams = filteredExams.where((exam) => exam.skill == skill).toList();
    }

    if (year != null) {
      filteredExams = filteredExams
          .where((exam) => exam.yearDescription.contains(year))
          .toList();
    }

    if (examNumber != null) {
      filteredExams = filteredExams
          .where((exam) => exam.examNumberDescription.contains(examNumber))
          .toList();
    }

    return filteredExams;
  }

  // Get available years
  List<String> getAvailableYears() {
    final years = <String>{};
    for (var exam in _exams) {
      final yearMatch = RegExp(r'\d{4}').firstMatch(exam.yearDescription);
      if (yearMatch != null) {
        years.add(yearMatch.group(0)!);
      }
    }
    final yearsList = years.toList();
    yearsList.sort((a, b) => b.compareTo(a)); // Sort descending
    return yearsList;
  }

  // Get available exam numbers
  List<String> getAvailableExamNumbers() {
    final examNumbers = <String>{};
    for (var exam in _exams) {
      examNumbers.add(exam.examNumberDescription);
    }
    final examNumbersList = examNumbers.toList();
    examNumbersList.sort();
    return examNumbersList;
  }

  // Get stats
  Map<String, dynamic> getStats() {
    final topik1Exams = _exams.where((exam) => exam.level == 'TOPIK Ⅰ').length;
    final topik2Exams = _exams.where((exam) => exam.level == 'TOPIK Ⅱ').length;
    final listeningExams = _exams.where((exam) => exam.skill == '듣기').length;
    final readingExams = _exams.where((exam) => exam.skill == '읽기').length;

    return {
      'totalExams': _exams.length,
      'topik1Exams': topik1Exams,
      'topik2Exams': topik2Exams,
      'listeningExams': listeningExams,
      'readingExams': readingExams,
    };
  }
}
