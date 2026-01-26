import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeSearchService {
  // YouTube Data API v3 key
  static const String _apiKey = 'AIzaSyAN-5eDl19Mu8qDdd7kxCYQmmQFQLK5tJc';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  static YouTubeSearchService? _instance;

  static YouTubeSearchService getInstance() {
    _instance ??= YouTubeSearchService();
    return _instance!;
  }

  Future<List<YouTubeSearchResult>> searchVideos(String query, {int maxResults = 10}) async {
    if (_apiKey == 'YOUR_YOUTUBE_API_KEY_HERE') {
      throw Exception('Vui lòng cấu hình YouTube API Key');
    }

    try {
      final url = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': maxResults.toString(),
        'key': _apiKey,
        'videoCaption': 'closedCaption', // Only videos with captions
        'relevanceLanguage': 'ko', // Prefer Korean content
      });

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout - không thể kết nối YouTube API');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => YouTubeSearchResult.fromJson(item)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('API Key không hợp lệ hoặc đã hết quota');
      } else {
        throw Exception('Lỗi tìm kiếm (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Không có kết nối internet');
      }
      rethrow;
    }
  }
}

class YouTubeSearchResult {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String description;
  final DateTime publishedAt;

  YouTubeSearchResult({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.description,
    required this.publishedAt,
  });

  factory YouTubeSearchResult.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    
    return YouTubeSearchResult(
      videoId: json['id']['videoId'] as String,
      title: snippet['title'] as String,
      channelTitle: snippet['channelTitle'] as String,
      thumbnailUrl: (thumbnails['medium'] ?? thumbnails['default'])['url'] as String,
      description: snippet['description'] as String,
      publishedAt: DateTime.parse(snippet['publishedAt'] as String),
    );
  }

  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
}
