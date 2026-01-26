import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/global_audio_manager.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isDark;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.isDark,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _audioManager = GlobalAudioManager();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioManager.addListener(_onManagerChanged);
  }

  @override
  void dispose() {
    _audioManager.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlay() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      await _audioManager.play(widget.audioUrl);
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = _audioManager.currentUrl == widget.audioUrl;
    final isPlaying = isCurrent && _audioManager.isPlaying;
    final position = isCurrent ? _audioManager.position : Duration.zero;
    final duration = isCurrent ? _audioManager.duration : Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.glassDark : AppColors.glassLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        ),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          IconButton(
            onPressed: isLoading ? null : _togglePlay,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 32,
                    color: AppColors.emerald,
                  ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Progress Slider
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: AppColors.emerald,
                    inactiveTrackColor: widget.isDark 
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.2),
                    thumbColor: AppColors.emerald,
                    overlayColor: AppColors.emerald.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble().clamp(position.inSeconds.toDouble(), double.infinity) == 0 ? 1.0 : duration.inSeconds.toDouble().clamp(position.inSeconds.toDouble(), double.infinity),
                    onChanged: isCurrent ? (value) {
                      _audioManager.seek(Duration(seconds: value.toInt()));
                    } : null,
                  ),
                ),
                // Time display
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

