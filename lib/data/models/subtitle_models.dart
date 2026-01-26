class Subtitle {
  final double start; // seconds
  final double duration; // seconds
  final String text;

  Subtitle({
    required this.start,
    required this.duration,
    required this.text,
  });

  factory Subtitle.fromJson(Map<String, dynamic> json) {
    // API returns milliseconds, convert to seconds
    return Subtitle(
      start: (json['start'] as num).toDouble() / 1000,
      duration: (json['duration'] as num).toDouble() / 1000,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'duration': duration,
      'text': text,
    };
  }

  double get endTime => start + duration;
}

class SubtitleResponse {
  final bool success;
  final String videoId;
  final String language;
  final int count;
  final List<Subtitle> subtitles;

  SubtitleResponse({
    required this.success,
    required this.videoId,
    required this.language,
    required this.count,
    required this.subtitles,
  });

  factory SubtitleResponse.fromJson(Map<String, dynamic> json) {
    return SubtitleResponse(
      success: json['success'] as bool? ?? false,
      videoId: json['video_id'] as String? ?? '',
      language: json['language'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => Subtitle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'video_id': videoId,
      'language': language,
      'count': count,
      'subtitles': subtitles.map((e) => e.toJson()).toList(),
    };
  }
}
