import 'package:flutter/material.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import 'mock_test_list_screen.dart';

class MockTestScreen extends StatelessWidget {
  const MockTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thi Thử TOPIK',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: Show filter modal
                        },
                        icon: Icon(
                          Icons.filter_list,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn cấp độ và kỹ năng để bắt đầu thi thử',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Mock Test Cards
                  _buildMockTestCard(
                    context,
                    level: 'TOPIK Ⅰ',
                    skill: '듣기',
                    title: 'TOPIK I - Nghe',
                    description: 'Thi thử kỹ năng nghe TOPIK I',
                    icon: Icons.headset,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildMockTestCard(
                    context,
                    level: 'TOPIK Ⅰ',
                    skill: '읽기',
                    title: 'TOPIK I - Đọc',
                    description: 'Thi thử kỹ năng đọc TOPIK I',
                    icon: Icons.book,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildMockTestCard(
                    context,
                    level: 'TOPIK Ⅱ',
                    skill: '듣기',
                    title: 'TOPIK II - Nghe',
                    description: 'Thi thử kỹ năng nghe TOPIK II',
                    icon: Icons.headset,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildMockTestCard(
                    context,
                    level: 'TOPIK Ⅱ',
                    skill: '읽기',
                    title: 'TOPIK II - Đọc',
                    description: 'Thi thử kỹ năng đọc TOPIK II',
                    icon: Icons.book,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTestCard(
    BuildContext context, {
    required String level,
    required String skill,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MockTestListScreen(
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
                  color: AppColors.emerald.withOpacity(isDark ? 0.2 : 0.15),
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
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.2),
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
