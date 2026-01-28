import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/audio_player_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/instructions.dart';
import '../../../data/models/topik_exam.dart';
import '../../../data/services/data_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../core/utils/global_audio_manager.dart';
import '../../widgets/exam/topik_question_widget.dart';
import '../../../data/services/transcript_service.dart';
import '../../widgets/exam/audio_transcript_widget.dart';

/// Practice Questions Screen - Shows ALL questions matching instruction range
/// Matches React Native practice flow exactly
class PracticeQuestionsScreen extends StatefulWidget {
  final String level;
  final String skill;
  final String instruction;

  const PracticeQuestionsScreen({
    super.key,
    required this.level,
    required this.skill,
    required this.instruction,
  });

  @override
  State<PracticeQuestionsScreen> createState() => _PracticeQuestionsScreenState();
}

/// Helper class to keep track of question with its parent exam and group
class QuestionWithInfo {
  final TOPIKQuestion question;
  final String examId;
  final String? examAudioUrl;
  final TOPIKInstructionGroup group;

  QuestionWithInfo({
    required this.question,
    required this.examId,
    this.examAudioUrl,
    required this.group,
  });
}

class _PracticeQuestionsScreenState extends State<PracticeQuestionsScreen> {
  String filterMode = 'all'; // 'all', 'done', 'undone'
  bool isLoading = true;
  final htmlUnescape = HtmlUnescape();
  
  /// Keeps track of questions answered while in "undone" mode so they don't disappear immediately
  final Set<String> _pendingAnsweredIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    GlobalAudioManager().stop();
    super.dispose();
  }

  void _loadInitialData() async {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      await progressProvider.loadProgress(authProvider.token!);
    }
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleAnswerSelect(String examId, String questionId, int optionIndex, bool isCorrect) {
    final uniqueId = '$examId-$questionId';
    
    // If in "undone" mode, add to pending set so it doesn't disappear immediately
    if (filterMode == 'undone') {
      setState(() {
        _pendingAnsweredIds.add(uniqueId);
      });
    }

    // Save to API via ProgressProvider
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();
    
    progressProvider.savePracticeAnswer(
      token: authProvider.token,
      examId: examId,
      questionId: questionId,
      answer: optionIndex + 1, // API expects 1-based index
      isCorrect: isCorrect,
    );
  }

  /// Get all questions matching the instruction range from ALL exams
  List<QuestionWithInfo> get allQuestionsSorted {
    final dataService = DataService.getInstance();
    final exams = dataService.getExamsByLevelAndSkill(widget.level, widget.skill);
    
    final range = Instructions.extractRange(widget.instruction);
    if (range == null) return [];
    
    final ranges = [range];
    final List<QuestionWithInfo> questions = [];
    
    for (var exam in exams) {
      for (var group in exam.instructionGroups) {
        for (var question in group.questions) {
          if (Instructions.isNumberInRange(question.number, ranges)) {
            questions.add(QuestionWithInfo(
              question: question,
              examId: exam.id,
              examAudioUrl: exam.audioUrl,
              group: group,
            ));
          }
        }
      }
    }
    
    // Sort by exam first, then by question number
    questions.sort((a, b) {
      final examCompare = a.examId.compareTo(b.examId);
      if (examCompare != 0) return examCompare;
      return a.question.number.compareTo(b.question.number);
    });
    
    return questions;
  }

  List<QuestionWithInfo> _filterQuestions(List<QuestionWithInfo> questions, ProgressProvider progressProvider, {String? mode}) {
    final currentMode = mode ?? filterMode;
    if (currentMode == 'all') return questions;
    
    return questions.where((q) {
      final uniqueId = '${q.examId}-${q.question.id}';
      final isDone = progressProvider.isQuestionAnswered(uniqueId);
      
      if (currentMode == 'done') {
        return isDone;
      } else {
        if (isDone && _pendingAnsweredIds.contains(uniqueId)) {
          return true;
        }
        return !isDone;
      }
    }).toList();
  }
  int _getFilterIndex(String mode) {
    switch (mode) {
      case 'all': return 0;
      case 'done': return 1;
      case 'undone': return 2;
      default: return 0;
    }
  }

  Widget _buildTabContent(String mode, List<QuestionWithInfo> questions, bool isDark, ProgressProvider progressProvider) {
    if (questions.isEmpty) {
      return _buildEmptyState(isDark);
    }
    
    return ListView.builder(
      key: PageStorageKey('practice_list_$mode'),
      padding: const EdgeInsets.all(12),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        bool showSharedHeader = true;
        if (index > 0) {
          final prev = questions[index - 1];
          final current = questions[index];
          if (prev.examId == current.examId && 
              prev.group.instruction == current.group.instruction &&
              prev.group.sharedContent?.value == current.group.sharedContent?.value) {
            showSharedHeader = false;
          }
        }

        return _buildQuestionItem(
          questions[index], 
          isDark, 
          progressProvider,
          showSharedHeader: showSharedHeader,
        );
      },
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Consumer<ProgressProvider>(
              builder: (context, progressProvider, child) {
                final allQuestions = allQuestionsSorted;
                final doneQuestions = _filterQuestions(allQuestionsSorted, progressProvider, mode: 'done');
                final undoneQuestions = _filterQuestions(allQuestionsSorted, progressProvider, mode: 'undone');
                
                return Column(
                  children: [
                    _buildHeader(isDark),
                    Expanded(
                      child: IndexedStack(
                        index: _getFilterIndex(filterMode),
                        children: [
                          _buildTabContent('all', allQuestions, isDark, progressProvider),
                          _buildTabContent('done', doneQuestions, isDark, progressProvider),
                          _buildTabContent('undone', undoneQuestions, isDark, progressProvider),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.level,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        Instructions.normalizeInstruction(widget.instruction),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildFilterTab('all', 'Tất cả', isDark),
                  _buildFilterTab('done', 'Đã làm', isDark),
                  _buildFilterTab('undone', 'Chưa làm', isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String mode, String label, bool isDark) {
    final isActive = filterMode == mode;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          if (filterMode != mode) {
            setState(() {
              _pendingAnsweredIds.clear();
              filterMode = mode;
            });

            if ((mode == 'done' || mode == 'undone')) {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.currentUser == null) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hãy đăng nhập để lưu giữ hành trình học tập và bảo toàn mọi nỗ lực của bạn nhé! ✨'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive 
                ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive 
                        ? (isDark ? Colors.white : AppColors.emerald)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildQuestionItem(
    QuestionWithInfo qInfo, 
    bool isDark, 
    ProgressProvider progressProvider, 
    {bool showSharedHeader = true}
  ) {
    final question = qInfo.question;
    final group = qInfo.group;
    final uniqueId = '${qInfo.examId}-${question.id}';
    
    final history = progressProvider.getQuestionHistory(uniqueId);
    final selectedIndex = history != null ? history.answer - 1 : null;
    final hasAnswered = selectedIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSharedHeader) ...[
          const SizedBox(height: 24),
          // Group Instruction
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

          // Group Audio (shared for all questions in group)
          if (group.groupAudioUrl != null) ...[
            const SizedBox(height: 12),
            AudioPlayerWidget(
              audioUrl: group.groupAudioUrl!,
              isDark: isDark,
            ),
          ],

          // Group Audio Transcript (show when all questions in group are answered)
          if (group.groupAudioUrl != null) ...[
            Builder(
              builder: (context) {
                // Check if all questions in this group are answered
                final allAnswered = group.questions.every((q) {
                  final uniqueId = '${qInfo.examId}-${q.id}';
                  return progressProvider.isQuestionAnswered(uniqueId);
                });

                if (!allAnswered) return const SizedBox.shrink();

                final transcriptService = TranscriptService.getInstance();
                final transcript = transcriptService.getTranscriptByAudioUrl(group.groupAudioUrl);

                if (transcript != null) {
                  return AudioTranscriptWidget(
                    transcript: transcript,
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          // Shared Content (Passage)
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
          
          // Group Image
          if (group.sharedContent != null && group.sharedContent!.src != null) ...[
             const SizedBox(height: 12),
             ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: CachedNetworkImage(imageUrl: group.sharedContent!.src!),
             ),
          ],

          // Example (Bo Gi)
          if (group.example.title.isNotEmpty || group.example.questionText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                  width: 1,
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
        ],

        TopikQuestionWidget(
          question: question,
          selectedIndex: selectedIndex,
          showFeedback: hasAnswered,
          onOptionSelected: (index) => _handleAnswerSelect(
            qInfo.examId,
            qInfo.question.id,
            index,
            question.options[index].isCorrect,
          ),
          isDark: isDark,
          examId: qInfo.examId,
          skill: widget.skill,
          audioUrl: question.questionAudioUrl,
        ),
      ],
    );
  }

  Widget _buildMarker(int index, bool showFeedback, bool isSelected, bool isCorrect, Color markerColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: markerColor.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: (showFeedback && (isSelected || isCorrect))
            ? Icon(isCorrect ? Icons.check : Icons.close, size: 16, color: markerColor)
            : Text(
                '${index + 1}',
                style: TextStyle(color: markerColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassDark : AppColors.glassLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
        ),
        child: const Text('Không tìm thấy câu hỏi phù hợp', textAlign: TextAlign.center),
      ),
    );
  }
}
