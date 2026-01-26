/// Audio Transcript Model
/// Represents the transcript of an audio file for TOPIK listening questions
class AudioTranscript {
  final String id;
  final String audioUrl;
  final String text;
  final List<Utterance> utterances;
  final double confidence;
  final int audioDuration;

  AudioTranscript({
    required this.id,
    required this.audioUrl,
    required this.text,
    required this.utterances,
    required this.confidence,
    required this.audioDuration,
  });

  factory AudioTranscript.fromJson(Map<String, dynamic> json) {
    return AudioTranscript(
      id: json['id'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      text: json['text'] ?? '',
      utterances: (json['utterances'] as List?)
              ?.map((e) => Utterance.fromJson(e))
              .toList() ??
          [],
      confidence: (json['confidence'] ?? 0).toDouble(),
      audioDuration: json['audioDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioUrl': audioUrl,
      'text': text,
      'utterances': utterances.map((e) => e.toJson()).toList(),
      'confidence': confidence,
      'audioDuration': audioDuration,
    };
  }

  /// Format transcript for display
  String get formattedText {
    if (text.isNotEmpty) {
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    if (utterances.isNotEmpty) {
      return utterances
          .map((u) => '${u.speaker}: ${u.text}')
          .join('\n\n');
    }

    return 'Không có transcript';
  }

  /// Get transcript with speaker labels
  List<SpeakerLine> get speakerLines {
    if (utterances.isEmpty) return [];
    
    return utterances.map((u) => SpeakerLine(
      speaker: u.speaker,
      text: u.text,
    )).toList();
  }
}

/// Represents a single utterance in a transcript
class Utterance {
  final String speaker;
  final String text;
  final double confidence;
  final int start;
  final int end;

  Utterance({
    required this.speaker,
    required this.text,
    required this.confidence,
    required this.start,
    required this.end,
  });

  factory Utterance.fromJson(Map<String, dynamic> json) {
    return Utterance(
      speaker: json['speaker'] ?? 'A',
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speaker': speaker,
      'text': text,
      'confidence': confidence,
      'start': start,
      'end': end,
    };
  }
}

/// Helper class for displaying speaker-based transcript
class SpeakerLine {
  final String speaker;
  final String text;

  SpeakerLine({
    required this.speaker,
    required this.text,
  });
}
