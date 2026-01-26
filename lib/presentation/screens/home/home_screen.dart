import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/auth_provider.dart';
import '../practice/topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Consumer<ProgressProvider>(
              builder: (context, progressProvider, child) {
                // Get real progress data
                final topik1Progress = progressProvider.getLevelProgress(AppConstants.topikI);
                final topik2Progress = progressProvider.getLevelProgress(AppConstants.topikII);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 32),
                      
                      // TOPIK I Card
                      _buildLevelCard(
                        context,
                        level: AppConstants.topikI,
                        title: 'TOPIK Ⅰ',
                        subtitle: 'Dành cho người mới bắt đầu',
                        listeningProgress: topik1Progress['skills']['듣기']['progressPercentage'] ?? 0.0,
                        readingProgress: topik1Progress['skills']['읽기']['progressPercentage'] ?? 0.0,
                        listeningStats: topik1Progress['skills']['듣기'],
                        readingStats: topik1Progress['skills']['읽기'],
                        isDark: isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // TOPIK II Card
                      _buildLevelCard(
                        context,
                        level: AppConstants.topikII,
                        title: 'TOPIK Ⅱ',
                        subtitle: 'Dành cho trình độ trung cấp - cao cấp',
                        listeningProgress: topik2Progress['skills']['듣기']['progressPercentage'] ?? 0.0,
                        readingProgress: topik2Progress['skills']['읽기']['progressPercentage'] ?? 0.0,
                        listeningStats: topik2Progress['skills']['듣기'],
                        readingStats: topik2Progress['skills']['읽기'],
                        isDark: isDark,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String level,
    required String title,
    required String subtitle,
    required double listeningProgress,
    required double readingProgress,
    required Map<String, dynamic> listeningStats,
    required Map<String, dynamic> readingStats,
    required bool isDark,
  }) {
    final isTopik2 = level == AppConstants.topikII;
    final primaryColor = isTopik2 ? AppColors.blue : AppColors.emerald;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: isDark ? AppColors.glassDark : Colors.white.withValues(alpha: 0.7),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicScreen(level: level),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'CẤP ĐỘ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: primaryColor,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                        ),
                      ),
                      Icon(
                        isTopik2 ? Icons.workspace_premium : Icons.stars,
                        color: primaryColor,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Progress Section Header
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 16, color: isDark ? Colors.white54 : Colors.black45),
                      const SizedBox(width: 8),
                      Text(
                        'TIẾN ĐỘ HỌC TẬP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : Colors.black45,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Listening Progress
                  _buildProgressBar(
                    context,
                    label: '듣기 (Nghe)',
                    progress: listeningProgress,
                    answeredQuestions: listeningStats['answeredQuestions'] ?? 0,
                    totalQuestions: listeningStats['totalQuestions'] ?? 0,
                    accuracyPercentage: listeningStats['accuracyPercentage'] ?? 0.0,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Reading Progress
                  _buildProgressBar(
                    context,
                    label: '읽기 (Đọc)',
                    progress: readingProgress,
                    answeredQuestions: readingStats['answeredQuestions'] ?? 0,
                    totalQuestions: readingStats['totalQuestions'] ?? 0,
                    accuracyPercentage: readingStats['accuracyPercentage'] ?? 0.0,
                    color: primaryColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context, {
    required String label,
    required double progress,
    required int answeredQuestions,
    required int totalQuestions,
    required double accuracyPercentage,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${progress.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: '%',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 8,
              width: MediaQuery.of(context).size.width * 0.7 * (progress / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.6), color],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (totalQuestions > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatChip(
                context,
                icon: Icons.check_circle_outline,
                label: '$answeredQuestions/$totalQuestions câu',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                context,
                icon: Icons.insights,
                label: 'Đúng ${accuracyPercentage.toStringAsFixed(0)}%',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, {required IconData icon, required String label, required bool isDark}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
