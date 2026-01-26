import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/instructions.dart';
import 'package:provider/provider.dart';
import '../../../providers/progress_provider.dart';
import 'practice_questions_screen.dart';

/// Instruction List Screen - Shows hardcoded instruction types for practice
class InstructionListScreen extends StatelessWidget {
  final String level;
  final String skill;

  const InstructionListScreen({
    super.key,
    required this.level,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get hardcoded instructions for this level and skill
    final instructions = Instructions.getInstructions(level, skill);

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
                              'Chọn dạng câu hỏi',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Instructions List
                Expanded(
                  child: instructions.isEmpty
                      ? Center(
                          child: Text(
                            'Không có dạng câu hỏi nào',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : Consumer<ProgressProvider>(
                          builder: (context, progressProvider, _) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: instructions.length,
                              itemBuilder: (context, index) {
                                final instruction = instructions[index];
                                final progress = progressProvider.getInstructionProgress(level, skill, instruction);
                                final answered = progress['answered'] as int;
                                final total = progress['total'] as int;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildInstructionCard(
                                    context,
                                    instruction: instruction,
                                    answered: answered,
                                    total: total,
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PracticeQuestionsScreen(
                                            level: level,
                                            skill: skill,
                                            instruction: instruction,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
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

  Widget _buildInstructionCard(
    BuildContext context, {
    required String instruction,
    required int answered,
    required int total,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final displayText = Instructions.normalizeInstruction(instruction);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$answered/$total câu đã làm',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
