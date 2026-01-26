import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/data_service.dart';
import '../../../data/models/topik_exam.dart';
import 'instruction_list_screen.dart';

class TopicScreen extends StatelessWidget {
  final String level;

  const TopicScreen({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataService = DataService.getInstance();

    // Get exams for this level
    final listeningExams = dataService.getExamsByLevelAndSkill(level, '듣기');
    final readingExams = dataService.getExamsByLevelAndSkill(level, '읽기');

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
                              level,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Chọn kỹ năng để luyện tập',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Skills List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Listening Skill
                      _buildSkillCard(
                        context,
                        skill: '듣기',
                        title: 'Nghe hiểu',
                        description: 'Luyện tập kỹ năng nghe',
                        icon: Icons.headset,
                        examCount: listeningExams.length,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 16),

                      // Reading Skill
                      _buildSkillCard(
                        context,
                        skill: '읽기',
                        title: 'Đọc hiểu',
                        description: 'Luyện tập kỹ năng đọc',
                        icon: Icons.book,
                        examCount: readingExams.length,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(
    BuildContext context, {
    required String skill,
    required String title,
    required String description,
    required IconData icon,
    required int examCount,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstructionListScreen(
                level: level,
                skill: skill,
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
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: isDark ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$examCount đề thi có sẵn',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
