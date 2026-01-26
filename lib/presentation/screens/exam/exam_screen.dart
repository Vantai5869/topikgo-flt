import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/audio_player_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/topik_exam.dart';
import '../../../data/services/data_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../widgets/exam/topik_question_widget.dart';

/// Mock Test Exam Screen - Has timer, submit button, shows answers only after submit
class MockTestExamScreen extends StatefulWidget {
  final String examId;
  final bool isMockTest;

  const MockTestExamScreen({
    super.key,
    required this.examId,
    this.isMockTest = true,
  });

  @override
  State<MockTestExamScreen> createState() => _MockTestExamScreenState();
}

class _MockTestExamScreenState extends State<MockTestExamScreen> {
  late TOPIKExam exam;
  late List<TOPIKQuestion> allQuestions;
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {}; // questionNumber -> selectedOptionIndex
  bool isLoading = true;
  bool isSubmitted = false;
  final htmlUnescape = HtmlUnescape();
  
  // Timer related
  Timer? _timer;
  int _remainingSeconds = 0;

  // Audio related
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _loadExam() {
    final dataService = DataService.getInstance();
    final loadedExam = dataService.getExamById(widget.examId);
    
    if (loadedExam == null) {
      Navigator.pop(context);
      return;
    }

    exam = loadedExam;
    
    // Flatten all questions from instruction groups
    allQuestions = [];
    for (var group in exam.instructionGroups) {
      allQuestions.addAll(group.questions);
    }

    // Set initial time based on skill
    if (widget.isMockTest) {
      _remainingSeconds = exam.skill == '듣기' ? 40 * 60 : 60 * 60;
      _startTimer();
      
      // Auto play audio for listening
      if (exam.skill == '듣기' && exam.audioUrl != null) {
        _playAudio();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _playAudio() async {
    try {
      if (exam.audioUrl != null) {
        await _audioPlayer.play(UrlSource(exam.audioUrl!));
        setState(() => _playerState = PlayerState.playing);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _toggleAudio() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      setState(() => _playerState = PlayerState.paused);
    } else {
      await _audioPlayer.resume();
      setState(() => _playerState = PlayerState.playing);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitExam(auto: true);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int questionNumber, int optionIndex) {
    if (isSubmitted) return; // Cannot change answers after submission
    
    setState(() {
      selectedAnswers[questionNumber] = optionIndex;
    });

    // Auto-save answer if logged in AND not a mock test (practice mode)
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    
    if (!widget.isMockTest && authProvider.token != null) {
      // Find the question by number
      final question = allQuestions.firstWhere((q) => q.number == questionNumber);
      final isCorrect = question.options[optionIndex].isCorrect;
      
      progressProvider.savePracticeAnswer(
        token: authProvider.token!,
        examId: widget.examId,
        questionId: question.id,
        answer: optionIndex + 1,
        isCorrect: isCorrect,
      );
    }
  }

  void _nextQuestion() {
    // Deprecated for list view
  }

  void _previousQuestion() {
    // Deprecated for list view
  }

  void _goToQuestion(int index) {
    setState(() {
      currentQuestionIndex = index;
    });
    Navigator.pop(context); // Close question navigator
  }

  void _showQuestionNavigator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _buildQuestionNavigator(),
    );
  }

  void _submitExam({bool auto = false}) {
    if (isSubmitted) return;

    _timer?.cancel();
    
    // Calculate score
    int correctCount = 0;
    for (var question in allQuestions) {
      final selectedIndex = selectedAnswers[question.number];
      if (selectedIndex != null && question.options[selectedIndex].isCorrect) {
        correctCount++;
      }
    }

    setState(() {
      isSubmitted = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(auto ? 'Hết giờ!' : 'Hoàn thành'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn đã trả lời đúng $correctCount/${allQuestions.length} câu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Điểm số: ${(correctCount / allQuestions.length * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.emerald),
            ),
            const SizedBox(height: 16),
            const Text('Bạn có thể xem lại đáp án chi tiết cho từng câu hỏi.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem lại bài làm'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close exam screen
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),
                
                // Questions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allQuestions.length,
                    itemBuilder: (context, index) {
                      final question = allQuestions[index];
                      
                      // Logic to decide if we should show the shared instruction/content
                      bool showSharedHeader = true;
                      if (index > 0) {
                        final prev = allQuestions[index - 1];
                        final current = allQuestions[index];
                        
                        // Find groups for both
                        TOPIKInstructionGroup? prevGroup;
                        TOPIKInstructionGroup? currentGroup;
                        
                        for (var g in exam.instructionGroups) {
                          if (g.questions.contains(prev)) prevGroup = g;
                          if (g.questions.contains(current)) currentGroup = g;
                          if (prevGroup != null && currentGroup != null) break;
                        }

                        if (prevGroup == currentGroup) {
                          showSharedHeader = false;
                        }
                      }

                      return _buildListItem(isDark, question, showSharedHeader: showSharedHeader);
                    },
                  ),
                ),
                
                // Navigation / Submit Bar
                _buildNavigationBar(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(bool isDark, TOPIKQuestion question, {required bool showSharedHeader}) {
    final selectedIndex = selectedAnswers[question.number];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSharedHeader) ...[
          const SizedBox(height: 24),
          ..._buildSharedHeader(isDark, question),
        ],
        
        TopikQuestionWidget(
          question: question,
          selectedIndex: selectedIndex,
          showFeedback: isSubmitted,
          onOptionSelected: (index) => _selectAnswer(question.number, index),
          isDark: isDark,
          examId: exam.id,
          skill: exam.skill,
        ),
      ],
    );
  }

  List<Widget> _buildSharedHeader(bool isDark, TOPIKQuestion question) {
    // Find the group this question belongs to
    TOPIKInstructionGroup? targetGroup;
    for (var g in exam.instructionGroups) {
      if (g.questions.contains(question)) {
        targetGroup = g;
        break;
      }
    }

    if (targetGroup == null) return [];
    final group = targetGroup;

    return [
      // Instruction
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: HtmlWidget(
          group.instruction,
          textStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
      
      // Passage (Shared Content)
      if (group.sharedContent != null && (group.sharedContent!.value != null || group.sharedContent!.type == 'text_with_insertion_points')) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: HtmlWidget(
            group.sharedContent!.value ?? '',
            textStyle: const TextStyle(
              fontSize: 15,
              height: 1.6,
            ),
            customStylesBuilder: (element) {
              for (var cls in TopikQuestionWidget.htmlCustomStyles.keys) {
                if (element.classes.contains(cls.replaceFirst('.', ''))) {
                  return TopikQuestionWidget.htmlCustomStyles[cls];
                }
              }
              return null;
            },
          ),
        ),
      ],

      // Example (Bo Gi)
      if (group.example.title.isNotEmpty || group.example.questionText.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.example.title.isNotEmpty)
                Center(
                  child: HtmlWidget(
                    group.example.title,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 8),
              HtmlWidget(group.example.questionText),
              if (group.example.options.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: group.example.options.map((opt) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? Colors.white38 : Colors.black38),
                          color: opt.isCorrect ? AppColors.emerald.withOpacity(0.2) : null,
                        ),
                        child: Center(
                          child: Text(
                            '${group.example.options.indexOf(opt) + 1}',
                            style: TextStyle(fontSize: 10, color: opt.isCorrect ? AppColors.emerald : null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      HtmlWidget(opt.text ?? ''),
                    ],
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.glassDark.withOpacity(0.8)
            : AppColors.glassLight.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (isSubmitted) {
                Navigator.pop(context);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thoát?'),
                    content: const Text('Tiến độ bài thi sẽ không được lưu. Bạn có chắc muốn thoát?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ở lại')),
                      TextButton(onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }, child: const Text('Thoát')),
                    ],
                  ),
                );
              }
            },
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.yearDescription,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  exam.examNumberDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isMockTest && !isSubmitted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exam.skill == '듣기' && exam.audioUrl != null)
                  IconButton(
                    onPressed: _toggleAudio,
                    icon: Icon(
                      _playerState == PlayerState.playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 22,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 300 ? AppColors.red.withOpacity(0.1) : AppColors.emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined, 
                        size: 14, 
                        color: _remainingSeconds < 300 ? AppColors.red : AppColors.emerald
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _remainingSeconds < 300 ? AppColors.red : AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            onPressed: _showQuestionNavigator,
            icon: Icon(Icons.grid_view, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(bool isDark) {
    final answeredCount = selectedAnswers.length;
    final progress = answeredCount / allQuestions.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.glassDark.withValues(alpha: 0.9)
            : AppColors.glassLight.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ: $answeredCount/${allQuestions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            if (!isSubmitted)
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _submitExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Nộp bài', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Thoát', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionNavigator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Danh sách câu hỏi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: allQuestions.length,
                itemBuilder: (context, index) {
                  final question = allQuestions[index];
                  final selectedOptIndex = selectedAnswers[question.number];
                  final isAnswered = selectedOptIndex != null;
                  final isCorrect = isAnswered && question.options[selectedOptIndex].isCorrect;
                  final isCurrent = index == currentQuestionIndex;

                  Color bgColor = Colors.grey.withOpacity(0.3);
                  Color textColor = isDark ? Colors.white : Colors.black;

                  if (isSubmitted) {
                    if (isAnswered) {
                      bgColor = isCorrect ? AppColors.emerald : AppColors.red;
                      textColor = Colors.white;
                    }
                  } else {
                    if (isAnswered) {
                      bgColor = AppColors.emerald;
                      textColor = Colors.white;
                    }
                  }

                  return InkWell(
                    onTap: () => _goToQuestion(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent ? Border.all(color: AppColors.blue, width: 2) : null,
                      ),
                      child: Center(
                        child: Text(
                          '${question.number}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
