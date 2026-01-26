import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../widgets/login_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
            child: Consumer2<AuthProvider, ProgressProvider>(
              builder: (context, authProvider, progressProvider, child) {
                final isLoggedIn = authProvider.isAuthenticated;
                final user = authProvider.currentUser;
                final progressData = progressProvider.progressData;

                // Get real stats
                final totalExamsCompleted = progressData?.totalExamsTaken ?? 0;
                final overallAccuracy = progressData?.overallAverageScorePercentage ?? 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Hồ sơ',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý tài khoản và theo dõi tiến độ',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      
                      // User Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.glassDark : AppColors.glassLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLoggedIn ? Icons.person : Icons.person_outline,
                                size: 48,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isLoggedIn ? (user?.name ?? user?.email ?? 'Người dùng') : 'Chưa đăng nhập',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            if (isLoggedIn && user?.email != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                user!.email,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (!isLoggedIn) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Đăng nhập để xem lại lịch sử luyện thi, tiến trình học tập, các dạng câu hỏi đã làm và những thiếu sót cần cải thiện.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (isLoggedIn) {
                                    // 1. Show loading indicator or handle sync
                                    if (authProvider.token != null) {
                                      await progressProvider.syncPendingProgress(authProvider.token!);
                                    }
                                    
                                    // 2. Perform logout and clear local cache
                                    await authProvider.logout();
                                    progressProvider.clearProgress();
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const LoginBottomSheet(),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLoggedIn ? AppColors.red.withValues(alpha: 0.2) : AppColors.blue,
                                  foregroundColor: isLoggedIn ? AppColors.red : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isLoggedIn ? Icons.logout : Icons.login,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLoggedIn ? 'Đăng xuất' : 'Đăng nhập',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Cards with real data
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.emoji_events,
                              iconColor: AppColors.yellow,
                              value: totalExamsCompleted.toString(),
                              label: 'Bài đã hoàn thành',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              icon: Icons.check_circle,
                              iconColor: AppColors.emerald,
                              value: '${overallAccuracy.toStringAsFixed(0)}%',
                              label: 'Tỷ lệ đúng',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // App Version
                      Center(
                        child: Text(
                          'Phiên bản ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.5) 
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                        ),
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

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
