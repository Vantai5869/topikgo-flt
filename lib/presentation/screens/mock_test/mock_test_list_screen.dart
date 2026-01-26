import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/data_service.dart';
import '../../../data/models/topik_exam.dart';
import '../exam/exam_screen.dart';

/// Mock Test List Screen - Shows list of exams for mock test mode
/// Navigates to MockTestExamScreen (with timer and submit)
class MockTestListScreen extends StatelessWidget {
  final String level;
  final String skill;

  const MockTestListScreen({
    super.key,
    required this.level,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataService = DataService.getInstance();

    // Get real exams from data service
    final exams = dataService.getExamsByLevelAndSkill(level, skill);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$level - ${skill == '듣기' ? 'Nghe hiểu' : 'Đọc hiểu'}',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${exams.length} đề thi thử',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Exams List
                Expanded(
                  child: exams.isEmpty
                      ? Center(
                          child: Text(
                            'Không có đề thi nào',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: exams.length,
                          itemBuilder: (context, index) {
                            final exam = exams[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildExamCard(
                                context,
                                exam: exam,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required TOPIKExam exam,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MockTestExamScreen(
                examId: exam.id,
                isMockTest: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassDark : AppColors.glassLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.yearDescription,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam.examNumberDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${exam.totalQuestions} câu',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    exam.skill == '듣기' ? Icons.headset : Icons.book,
                    size: 16,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exam.skill == '듣기' ? 'Nghe hiểu' : 'Đọc hiểu',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    exam.skill == '듣기' ? '~40 phút' : '~60 phút',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
