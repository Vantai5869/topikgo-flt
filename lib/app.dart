import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/app_update_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/mock_test/mock_test_screen.dart';
import 'presentation/screens/youtube_learning/youtube_learning_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

class TopikGoApp extends StatelessWidget {
  const TopikGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'TOPIK GO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hideBottomNav = false;

  String? _lastToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
      _checkForUpdate();
    });
  }

  /// Check for app updates on startup
  void _checkForUpdate() {
    // Check for update with flexible update (user can skip)
    // Set forceUpdate: true for critical updates that require immediate installation
    AppUpdateService().checkForUpdate(context, forceUpdate: false);
  }

  void _setupAuthListener() {
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();

    // Initial check
    if (authProvider.token != null) {
      _lastToken = authProvider.token;
      progressProvider.loadProgress(_lastToken!, force: true);
    }

    // Listen for changes (e.g., login/logout)
    authProvider.addListener(() {
      final newToken = authProvider.token;
      if (newToken != _lastToken) {
        if (newToken != null) {
          // User just logged in
          progressProvider.loadProgress(newToken, force: true);
        } else {
          // User just logged out
          progressProvider.clearProgress();
        }
        _lastToken = newToken;
      }
    });
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      const MockTestScreen(),
      YouTubeLearningScreen(
        onFullscreenChanged: (isFullscreen) {
          setState(() {
            _hideBottomNav = isFullscreen;
          });
        },
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: _hideBottomNav
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.6)
            : Colors.black.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Luyện tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Thi thử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones_outlined),
            activeIcon: Icon(Icons.headphones),
            label: 'Luyện nghe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
