import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../widgets/gradient_background.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/subtitle_models.dart';
import '../../../data/services/youtube_subtitle_service.dart';
import 'package:provider/provider.dart';
import '../../../data/services/youtube_search_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/login_bottom_sheet.dart';

class YouTubeLearningScreen extends StatefulWidget {
  final Function(bool)? onFullscreenChanged;

  const YouTubeLearningScreen({super.key, this.onFullscreenChanged});

  @override
  State<YouTubeLearningScreen> createState() => _YouTubeLearningScreenState();
}

class _YouTubeLearningScreenState extends State<YouTubeLearningScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final YouTubeSubtitleService _subtitleService = YouTubeSubtitleService.getInstance();
  final YouTubeSearchService _searchService = YouTubeSearchService.getInstance();
  final List<GlobalKey> _subtitleKeys = [];
  
  YoutubePlayerController? _playerController;
  List<Subtitle> _subtitles = [];
  List<Subtitle> _translatedSubtitles = [];
  bool _isLoading = false;
  bool _isTranslating = false;
  bool _isSearching = false;
  String? _error;
  String? _currentVideoId;
  String? _videoTitle;
  int _activeSubtitleIndex = -1;
  int _inputTabIndex = 0; // 0: Search, 1: Direct Link (swapped previously)
  List<YouTubeSearchResult> _searchResults = [];
  bool _hasSearched = false;
  List<Map<String, String>> _videoHistory = [];
  late StorageService _storage;
  String? _lastUserId;
  StateSetter? _modalSetState; // Store modal's setState to trigger rebuild

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  Future<void> _initHistory() async {
    _storage = await StorageService.getInstance();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    try {
      // 1. Get current local history
      final localHistory = _storage.getYouTubeHistory(userId: userId);

      // 2. Sync guest history to server if just logged in
      if (userId != null && _lastUserId == null) {
        final guestHistory = _storage.getYouTubeHistory(userId: null);
        if (guestHistory.isNotEmpty) {
          final syncList = guestHistory.map((v) => {
                'videoId': v['id'],
                'title': v['title'],
                'thumbnailUrl': v['thumbnailUrl'] ??
                    'https://img.youtube.com/vi/${v['id']}/mqdefault.jpg',
              }).toList();

          try {
            await authProvider.syncYouTubeVideos(syncList);
            await _storage.saveYouTubeHistory([], userId: null);
          } catch (e) {
            // Silently fail or handle error without internal logging
          }
        }
      }

      if (authProvider.isAuthenticated) {
        try {
          final serverHistory = await authProvider.getYouTubeSavedVideos();

          // Smart Sync: Find local items missing from server
          final serverIds =
              serverHistory.map((v) => v['videoId']?.toString()).toSet();
          final missingLocal =
              localHistory.where((v) => !serverIds.contains(v['id'])).toList();

          if (missingLocal.isNotEmpty) {
            try {
              final syncList = missingLocal.map((v) => {
                    'videoId': v['id'],
                    'title': v['title'],
                    'thumbnailUrl': v['thumbnailUrl'] ??
                        'https://img.youtube.com/vi/${v['id']}/mqdefault.jpg',
                  }).toList();
              await authProvider.syncYouTubeVideos(syncList);

              // Refresh server history
              final updatedServerHistory =
                  await authProvider.getYouTubeSavedVideos();
              serverHistory.clear();
              serverHistory.addAll(updatedServerHistory);
            } catch (syncError) {
              // Handle error silently
            }
          }

          final mappedServerHistory = serverHistory.map((v) => {
                'id': (v['videoId'] ?? '').toString(),
                'url': 'https://www.youtube.com/watch?v=${v['videoId']}',
                'title': (v['title'] ?? 'Video YouTube').toString(),
                'thumbnailUrl': (v['thumbnailUrl'] ??
                        'https://img.youtube.com/vi/${v['videoId']}/mqdefault.jpg')
                    .toString(),
                'timestamp': (v['updatedAt'] ??
                        v['createdAt'] ??
                        DateTime.now().toIso8601String())
                    .toString(),
                'duration': 'Đã học',
              }).toList();

          // Merge: use video id as key
          final Map<String, Map<String, String>> merged = {};

          for (var v in localHistory) {
            if (v['id'] != null) merged[v['id']!] = v;
          }
          for (var v in mappedServerHistory) {
            if (v['id'] != null) merged[v['id']!] = v;
          }

          final finalHistory = merged.values.toList();
          finalHistory.sort((a, b) {
            final tA = a['timestamp'] ?? '';
            final tB = b['timestamp'] ?? '';
            return tB.compareTo(tA);
          });

          _videoHistory = finalHistory;
          await _storage.saveYouTubeHistory(_videoHistory, userId: userId);
        } catch (serverError) {
          _videoHistory = localHistory;
        }
      } else {
        // Unauthenticated: Just use local history
        _videoHistory = localHistory;
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Ignore errors in background history init
    }
  }

  Future<void> _addToHistory(String id, String url, String title) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    final now = DateTime.now().toIso8601String();
    final thumb = 'https://img.youtube.com/vi/$id/mqdefault.jpg';

    // Local update first
    setState(() {
      _videoHistory.removeWhere((item) => item['id'] == id);
      _videoHistory.insert(0, {
        'id': id,
        'url': url,
        'title': title,
        'thumbnailUrl': thumb,
        'timestamp': now,
        'duration': 'Đã học',
      });

      final limit = authProvider.isAuthenticated ? 40 : 10;
      if (_videoHistory.length > limit) {
        _videoHistory = _videoHistory.sublist(0, limit);
      }
    });

    // Save locally
    await _storage.saveYouTubeHistory(_videoHistory, userId: userId);
    
    // Save to server if authenticated
    if (authProvider.isAuthenticated) {
      authProvider.saveYouTubeVideo({
        'videoId': id,
        'title': title,
        'thumbnailUrl': thumb,
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check for user change to reload history
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.id;
    if (currentUserId != _lastUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // We DON'T update _lastUserId here anymore, _initHistory does it
        // after checking its value for sync detection.
        _initHistory();
      });
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            const GradientBackground(),
            SafeArea(
              child: _currentVideoId == null
                  ? _buildInputView(isDark)
                  : _buildVideoView(isDark),
            ),
            if (_isLoading) _buildLoadingOverlay(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.92),
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.7 + (value * 0.3),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with pulse animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween(begin: 0.95, end: 1.05),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  onEnd: () {
                    // Repeat animation
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Đang tải video',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.blue, AppColors.emerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Luyện nghe qua YouTube',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Add New Video Button
          _buildAddVideoButton(isDark),
          
          const SizedBox(height: 32),
          
          // Watched Videos Section
          _buildWatchedVideos(isDark),
        ],
      ),
    );
  }

  Widget _buildAddVideoButton(bool isDark) {
    return GestureDetector(
      onTap: _showAddVideoModal,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]
                : [AppColors.blue.withValues(alpha: 0.08), AppColors.emerald.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.blue.withValues(alpha: 0.1),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm video mới',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dán link hoặc tìm kiếm bài học',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white24 : Colors.black12,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVideoModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Store the modal's setState for use in search handler
          _modalSetState = setModalState;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle line
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header with gradient
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: 0.08),
                        AppColors.emerald.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.blue, AppColors.emerald],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.video_library_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thêm bài học mới',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tìm kiếm hoặc dán link YouTube',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModalTab('Tìm kiếm', Icons.search_rounded, 0, isDark, setModalState),
                      ),
                      Expanded(
                        child: _buildModalTab('Link YouTube', Icons.link_rounded, 1, isDark, setModalState),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        _inputTabIndex == 0
                            ? _buildSearchTab(isDark)
                            : _buildDirectLinkTab(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    ).whenComplete(() {
      // Clear the reference when modal closes
      _modalSetState = null;
    });
  }

  Widget _buildModalTab(String label, IconData icon, int index, bool isDark, StateSetter setModalState) {
    final isActive = _inputTabIndex == index;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _inputTabIndex = index;
        });
        setState(() {}); // Still update parent for view consistency
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [AppColors.blue, AppColors.emerald],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView(bool isDark) {
    return Column(
      children: [
        // Compact Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () {
                  setState(() {
                    _playerController?.dispose();
                    _playerController = null;
                    _currentVideoId = null;
                    _videoTitle = null;
                    _subtitles = [];
                    _translatedSubtitles = [];
                    _activeSubtitleIndex = -1;
                    _error = null;
                    // Notify parent to show bottom nav again
                    widget.onFullscreenChanged?.call(false);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _videoTitle ?? 'Luyện nghe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Video Player
        if (_playerController != null)
          YoutubePlayer(
            controller: _playerController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.blue,
            progressColors: ProgressBarColors(
              playedColor: AppColors.blue,
              handleColor: AppColors.blue,
            ),
          ),

        // Loading or Error
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Subtitles List
        if (_subtitles.isNotEmpty)
          Expanded(
            child: _buildSubtitlesList(isDark),
          ),
      ],
    );
  }

  Widget _buildSubtitlesList(bool isDark) {
    // Initialize keys for each subtitle
    if (_subtitleKeys.length != _subtitles.length) {
      _subtitleKeys.clear();
      _subtitleKeys.addAll(
        List.generate(_subtitles.length, (_) => GlobalKey()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.glassDark.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _subtitles.length,
        itemBuilder: (context, index) {
          final subtitle = _subtitles[index];
          final translation = index < _translatedSubtitles.length 
              ? _translatedSubtitles[index] 
              : null;
          final isActive = index == _activeSubtitleIndex;

          return GestureDetector(
            key: _subtitleKeys[index],
            onTap: () => _seekToSubtitle(subtitle.start),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.blue.withValues(alpha: isDark ? 0.2 : 0.12)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.blue.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Korean subtitle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                height: 1.5,
                                fontSize: 16,
                              ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.headphones,
                            color: AppColors.blue,
                            size: 16,
                          ),
                        ),
                    ],
                  ),

                  // Translation
                  if (translation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      translation.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                            height: 1.4,
                            fontSize: 14,
                          ),
                    ),
                  ] else if (_isTranslating) ...[
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      width: 200,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildDirectLinkTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // URL TextField with Paste button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'youtube.com/watch?v=...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.blue,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: isDark ? Colors.white54 : Colors.black54,
                    size: 22,
                  ),
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: isDark ? Colors.white54 : Colors.black54,
                            size: 20,
                          ),
                          onPressed: () {
                            _urlController.clear();
                            setState(() {});
                            _modalSetState?.call(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  _modalSetState?.call(() {});
                },
                onSubmitted: (_) => _handleLoadVideo(),
              ),
            ),
            const SizedBox(width: 10),
            // Paste button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: 0.15),
                    AppColors.emerald.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                onPressed: _pasteFromClipboard,
                icon: Icon(
                  Icons.content_paste_rounded,
                  color: AppColors.blue,
                  size: 22,
                ),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Load Button with gradient
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: (_isLoading || _urlController.text.trim().isEmpty)
                ? null
                : LinearGradient(
                    colors: [AppColors.blue, AppColors.emerald],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: (_isLoading || _urlController.text.trim().isEmpty)
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05))
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: (_isLoading || _urlController.text.trim().isEmpty)
                ? null
                : [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (_isLoading || _urlController.text.trim().isEmpty)
                  ? null
                  : _handleLoadVideo,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: (_isLoading || _urlController.text.trim().isEmpty)
                          ? (isDark ? Colors.white24 : Colors.black26)
                          : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bắt đầu bài học',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: (_isLoading || _urlController.text.trim().isEmpty)
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field with inline icon button
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          style: Theme.of(context).textTheme.bodyLarge,
          onChanged: (value) {
            if (_hasSearched) {
              setState(() {
                _hasSearched = false;
              });
              _modalSetState?.call(() {
                _hasSearched = false;
              });
            } else {
              // Trigger modal rebuild to show/hide suffixIcon or other state changes
              _modalSetState?.call(() {});
            }
          },
          decoration: InputDecoration(
            hintText: 'Nhập tên video tiếng Hàn...',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.blue,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon: Icon(
              Icons.video_library_rounded,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 24,
            ),
            suffixIcon: _isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.blue),
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.blue, AppColors.emerald],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: () {
                        _searchFocus.unfocus();
                        _handleSearch();
                      },
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
          ),
          onSubmitted: (_) {
            _searchFocus.unfocus();
            _handleSearch();
          },
        ),
        
        // Search results
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '${_searchResults.length} kết quả',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          
          // Limited height scrollable results
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildSearchResultItem(_searchResults[index], isDark);
              },
            ),
          ),
        ] else if (_hasSearched && !_isSearching) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy kết quả nào',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy thử với từ khóa khác nhé',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultItem(YouTubeSearchResult result, bool isDark) {
    return GestureDetector(
      onTap: () {
        _urlController.text = result.videoUrl;
        _handleLoadVideo();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                result.thumbnailUrl,
                width: 120,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 68,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  child: const Icon(Icons.video_library),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.channelTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: AppColors.emerald,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _urlController.text = data.text!;
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: _urlController.text.length),
      );
    }
  }

  Widget _buildWatchedVideos(bool isDark) {
    // Show real history or demo if empty
    final displayList = _videoHistory.isNotEmpty 
        ? _videoHistory 
        : [{
            'id': '8D3X8uCv_bA',
            'url': 'https://www.youtube.com/watch?v=8D3X8uCv_bA',
            'title': 'Luyện nghe tiếng Hàn qua tin tức',
            'duration': 'Video mẫu',
          }];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.video_library,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                _videoHistory.isEmpty ? 'Video mẫu' : 'Video đã học',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        if (_videoHistory.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Hãy bắt đầu bài học đầu tiên của bạn',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
          ),
        ],
        const SizedBox(height: 12),
        ...displayList.map((video) => _buildHistoryItem(video, isDark)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, String> video, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _urlController.text = video['url']!;
            _handleLoadVideo();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // Thumbnail with real image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://img.youtube.com/vi/${video['id']}/mqdefault.jpg',
                    width: 100,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 60,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Video Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            video['duration']!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showError('Vui lòng nhập từ khóa tìm kiếm');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
      _hasSearched = true;
    });

    try {
      final results = await _searchService.searchVideos(query, maxResults: 10);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        // Also update modal if it's open
        _modalSetState?.call(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _modalSetState?.call(() {
          _isSearching = false;
        });
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handleLoadVideo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Vui lòng nhập link YouTube');
      return;
    }

    // Close modal if open
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }

    final videoId = _subtitleService.extractVideoId(url);
    if (videoId == null) {
      _showError('Link YouTube không hợp lệ');
      return;
    }

    // Login requirement check
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      // Check if this video is already in history
      final isAlreadyInHistory = _videoHistory.any((v) => v['id'] == videoId);
      if (!isAlreadyInHistory && _videoHistory.length >= 2) {
        _showLoginRequiredDialog();
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch subtitles
      final response = await _subtitleService.fetchSubtitles(videoId, lang: 'ko');

      if (!response.success || response.subtitles.isEmpty) {
        throw Exception('Video không có phụ đề tiếng Hàn');
      }

      // Initialize YouTube player
      _playerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          controlsVisibleAtStart: true,
        ),
      );

      // Listen to player state changes to update active subtitle
      _playerController!.addListener(_onPlayerStateChange);

      setState(() {
        _currentVideoId = videoId;
        _subtitles = response.subtitles;
        _isLoading = false;
      });

      // Get video title after player is ready
      _getVideoTitle(videoId);

      // Auto-translate to Vietnamese
      _translateSubtitles();
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isLoading = false;
        _error = errorMessage;
      });
      // Show error notification to user
      _showError(errorMessage);
    }
  }

  Future<void> _translateSubtitles() async {
    if (_subtitles.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final translated = await _subtitleService.translateSubtitles(
        _subtitles,
        'vi', // to Vietnamese
        'ko', // from Korean
      );
      
      setState(() {
        _translatedSubtitles = translated;
        _isTranslating = false;
      });
    } catch (e) {
      setState(() {
        _isTranslating = false;
      });
      // Show error to user
      _showError('Không thể dịch phụ đề. Video vẫn xem được.');
    }
  }



  Future<void> _getVideoTitle(String videoId) async {
    // Try to get title from YouTube oEmbed API (no API key needed)
    try {
      final response = await http.get(
        Uri.parse('https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final title = data['title'] as String?;
        
        if (title != null && title.isNotEmpty) {
          setState(() {
            _videoTitle = title;
            widget.onFullscreenChanged?.call(true);
          });
          _addToHistory(videoId, 'https://www.youtube.com/watch?v=$videoId', title);
          return;
        }
      }
    } catch (e) {
      // If oEmbed fails, try player metadata
    }

    // Fallback: Poll player metadata
    int attempts = 0;
    const maxAttempts = 10;
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_playerController != null && _playerController!.value.isReady) {
          final title = _playerController!.metadata.title;
          if (title.isNotEmpty) {
            setState(() {
              _videoTitle = title;
              widget.onFullscreenChanged?.call(true);
            });
            _addToHistory(videoId, 'https://www.youtube.com/watch?v=$videoId', title);
            return;
          }
        }
        attempts++;
      }

    // Default title if all fails after timeout
    setState(() {
      _videoTitle = 'Video YouTube';
      widget.onFullscreenChanged?.call(true);
    });
    _addToHistory(videoId, 'https://www.youtube.com/watch?v=$videoId', 'Video YouTube');
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.blue),
            SizedBox(width: 10),
            Text('Yêu cầu đăng nhập'),
          ],
        ),
        content: const Text(
          'Bạn đã đạt giới hạn 2 video học thử. Vui lòng đăng nhập để lưu lịch sử và học không giới hạn hàng nghìn video khác nhé!',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Để sau', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              LoginBottomSheet.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }

  void _onPlayerStateChange() {
    if (_playerController == null || !_playerController!.value.isReady) return;

    final currentTime = _playerController!.value.position.inMilliseconds / 1000;
    final newIndex = _findActiveSubtitleIndex(currentTime);

    if (newIndex != _activeSubtitleIndex) {
      setState(() {
        _activeSubtitleIndex = newIndex;
      });

      // Auto-scroll to active subtitle
      if (newIndex >= 0 && newIndex < _subtitleKeys.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = _subtitleKeys[newIndex].currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.3,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  int _findActiveSubtitleIndex(double currentTime) {
    if (_subtitles.isEmpty) return -1;

    int bestMatch = -1;
    double closestStart = -1;

    for (int i = 0; i < _subtitles.length; i++) {
      final sub = _subtitles[i];
      final endTime = sub.start + sub.duration;

      if (currentTime >= sub.start && currentTime < endTime) {
        // If multiple subtitles match, choose the one with the closest (latest) start time
        if (sub.start > closestStart) {
          closestStart = sub.start;
          bestMatch = i;
        }
      }
    }

    return bestMatch;
  }

  void _seekToSubtitle(double startTime) {
    if (_playerController != null && _playerController!.value.isReady) {
      _playerController!.seekTo(Duration(milliseconds: (startTime * 1000).round()));
      _playerController!.play();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
