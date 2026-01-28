import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/subtitle_models.dart';

class YouTubeSubtitleService {
  static const String baseUrl = 'http://20.196.152.29:8888';

  static YouTubeSubtitleService? _instance;

  static YouTubeSubtitleService getInstance() {
    _instance ??= YouTubeSubtitleService();
    return _instance!;
  }

  Future<SubtitleResponse> fetchSubtitles(String videoId, {String lang = 'ko'}) async {
    try {
      final url = Uri.parse('$baseUrl/subtitles?video_id=$videoId&lang=$lang');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Không thể kết nối đến server');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubtitleResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Video không có phụ đề tiếng Hàn!');
      } else if (response.statusCode == 429) {
        // Check if it's actually a "no subtitles" case from YouTube
        if (response.body.contains('Failed to fetch subtitle content from YouTube') ||
            response.body.contains('detail')) {
          throw Exception('Video không có phụ đề tiếng Hàn');
        }
        throw Exception('Quá nhiều yêu cầu. Vui lòng thử lại sau vài giây');
      } else {
        throw Exception('Lỗi tải phụ đề (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.');
      }
      rethrow;
    }
  }

  Future<List<Subtitle>> translateSubtitles(
    List<Subtitle> subtitles, 
    String toLang, 
    String fromLang
  ) async {
    try {
      final url = Uri.parse('$baseUrl/translate-subtitles');
      
      // Convert to milliseconds for API
      final subsInMs = subtitles.map((sub) => {
        'start': (sub.start * 1000).round(),
        'duration': (sub.duration * 1000).round(),
        'text': sub.text,
      }).toList();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subtitles': subsInMs,
          'to_lang': toLang,
          'from_lang': fromLang,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Translation timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['translated_subtitles'] != null) {
          final translatedList = (data['translated_subtitles'] as List)
              .map((sub) => Subtitle.fromJson(sub as Map<String, dynamic>))
              .toList();
          return translatedList;
        }
        throw Exception('Translation failed');
      } else {
        throw Exception('Translation error (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Không thể dịch phụ đề: ${e.toString()}');
    }
  }

  String? extractVideoId(String url) {
    // Pattern 1: https://www.youtube.com/watch?v=VIDEO_ID
    // Pattern 2: https://youtu.be/VIDEO_ID
    // Pattern 3: Just the VIDEO_ID itself
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }
}
