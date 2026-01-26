import 'package:flutter/material.dart';
import '../../../data/models/audio_transcript.dart';

/// Widget to display audio transcript
/// Shows the transcript of listening questions after user has answered
class AudioTranscriptWidget extends StatelessWidget {
  final AudioTranscript transcript;
  final bool isDark;

  const AudioTranscriptWidget({
    super.key,
    required this.transcript,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final speakerLines = transcript.speakerLines;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.blue.withValues(alpha: 0.08) 
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.blue.withValues(alpha: 0.2) 
              : Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.subtitles_outlined,
                size: 18,
                color: isDark ? Colors.blue[300] : Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Lời thoại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Transcript content
          if (speakerLines.isNotEmpty)
            ...speakerLines.map((line) => _buildSpeakerLine(line))
          else
            Text(
              transcript.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeakerLine(SpeakerLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker label
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getSpeakerColor(line.speaker).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                line.speaker,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _getSpeakerColor(line.speaker),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Speaker text
          Expanded(
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpeakerColor(String speaker) {
    switch (speaker.toUpperCase()) {
      case 'A':
        return Colors.purple;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
