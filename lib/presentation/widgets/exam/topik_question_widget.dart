import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/topik_exam.dart';
import '../../../data/services/transcript_service.dart';
import '../audio_player_widget.dart';
import 'audio_transcript_widget.dart';

class TopikQuestionWidget extends StatelessWidget {
  final TOPIKQuestion question;
  final int? selectedIndex;
  final bool showFeedback;
  final Function(int) onOptionSelected;
  final bool isDark;
  final String? examId;
  final String? skill;
  final String? audioUrl; // Audio URL for transcript lookup

  const TopikQuestionWidget({
    super.key,
    required this.question,
    this.selectedIndex,
    required this.showFeedback,
    required this.onOptionSelected,
    required this.isDark,
    this.examId,
    this.skill,
    this.audioUrl,
  });

  static Map<String, Map<String, String>> get htmlCustomStyles => {
        '.blank-marker': {
          'color': '#10B981',
          'font-weight': 'bold',
          'text-decoration': 'underline',
        },
        '.insertion-point': {
          'color': '#10B981',
          'font-weight': 'bold',
          'border': '1px solid #10B981',
          'padding': '2px 4px',
          'border-radius': '4px',
          'margin': '0 2px',
        },
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Câu ${question.number}',
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (examId != null)
                      Text(
                        'Đề ${examId!.split('_').last}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    if (showFeedback && selectedIndex != null)
                      Icon(
                        question.options[selectedIndex!].isCorrect ? Icons.check_circle : Icons.cancel,
                        color: question.options[selectedIndex!].isCorrect ? AppColors.emerald : AppColors.red,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Audio (Question specific or Exam general)
                if (question.questionAudioUrl != null) ...[
                  AudioPlayerWidget(audioUrl: question.questionAudioUrl!, isDark: isDark),
                  const SizedBox(height: 16),
                ],

                // Question content (Insertion task sentence)
                if (question.content.type == 'insertion_task' && question.content.sentenceToInsert != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                    ),
                    child: HtmlWidget(
                      question.content.sentenceToInsert!,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Ordering task items
                if (question.content.type == 'ordering_task' && question.content.items != null) ...[
                  const SizedBox(height: 8),
                  ...question.content.items!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.marker} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: HtmlWidget(item.text)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                ],

                // Main Question Text
                if (question.content.value != null && question.content.type != 'insertion_task') ...[
                  HtmlWidget(
                    question.content.value!,
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    customStylesBuilder: (element) {
                      for (var cls in htmlCustomStyles.keys) {
                        if (element.classes.contains(cls.replaceFirst('.', ''))) {
                          return htmlCustomStyles[cls];
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),

          // Question Image (Full Width - Outside inner Padding)
          if (question.content.src != null) ...[
            CachedNetworkImage(
              imageUrl: question.content.src!,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
            const SizedBox(height: 16),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Options
                if (question.options.any((o) => o.imageSrc != null))
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                    children: List.generate(question.options.length, (index) {
                      final option = question.options[index];
                      return _buildOptionCard(
                        option: option,
                        index: index,
                        isSelected: selectedIndex == index,
                        isDark: isDark,
                        isGrid: true,
                      );
                    }),
                  )
                else
                  ...List.generate(question.options.length, (index) {
                    final option = question.options[index];
                    return _buildOptionCard(
                      option: option,
                      index: index,
                      isSelected: selectedIndex == index,
                      isDark: isDark,
                    );
                  }),
              ],
            ),
          ),

          // Audio Transcript (show after answering)
          if (showFeedback && audioUrl != null)
            Builder(
              builder: (context) {
                final transcriptService = TranscriptService.getInstance();
                final transcript = transcriptService.getTranscriptByAudioUrl(audioUrl);
                
                if (transcript != null) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AudioTranscriptWidget(
                      transcript: transcript,
                      isDark: isDark,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required TOPIKOption option,
    required int index,
    required bool isSelected,
    required bool isDark,
    bool isGrid = false,
  }) {
    final isCorrect = option.isCorrect;
    Color backgroundColor = Colors.transparent;
    Color borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);
    Color textColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8);
    Color markerColor = isDark ? Colors.white54 : Colors.black45;

    // Interaction is disabled if:
    // 1. Practice mode: user has already answered this question (showFeedback is true)
    // 2. Mock Test: the exam has been submitted
    final bool isLocked = showFeedback;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = AppColors.emerald.withOpacity(0.5);
        backgroundColor = AppColors.emerald.withOpacity(0.05);
        textColor = AppColors.emerald;
        markerColor = AppColors.emerald;
      } else if (isSelected) {
        borderColor = AppColors.red.withOpacity(0.5);
        backgroundColor = AppColors.red.withOpacity(0.05);
        textColor = AppColors.red;
        markerColor = AppColors.red;
      }
    } else if (isSelected) {
      borderColor = AppColors.emerald;
      backgroundColor = AppColors.emerald.withOpacity(0.1);
      textColor = AppColors.emerald;
      markerColor = AppColors.emerald;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : () => onOptionSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 0.8),
            ),
            clipBehavior: isGrid ? Clip.antiAlias : Clip.none,
            child: isGrid
                ? Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        child: Center(
                          child: _buildMarker(index, isSelected, isCorrect, markerColor),
                        ),
                      ),
                      if (option.imageSrc != null)
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: option.imageSrc!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      _buildMarker(index, isSelected, isCorrect, markerColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: option.imageSrc != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(imageUrl: option.imageSrc!),
                              )
                            : HtmlWidget(
                                option.text ?? '',
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(int index, bool isSelected, bool isCorrect, Color markerColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: markerColor.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: (showFeedback && (isSelected || isCorrect))
            ? Icon(isCorrect ? Icons.check : Icons.close, size: 16, color: markerColor)
            : Text(
                '${index + 1}',
                style: TextStyle(color: markerColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
