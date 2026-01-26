import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/audio_transcript.dart';

/// Service for managing audio transcripts
/// Provides quick lookup of transcripts by audio URL
class TranscriptService {
  static TranscriptService? _instance;
  final Map<String, AudioTranscript> _transcriptMap = {};
  bool _isLoaded = false;

  TranscriptService._();

  static TranscriptService getInstance() {
    _instance ??= TranscriptService._();
    return _instance!;
  }

  /// Load transcripts from JSON file
  Future<void> loadTranscripts() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/audio-transcripts.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      for (var item in jsonData) {
        final transcript = AudioTranscript.fromJson(item);
        if (transcript.audioUrl.isNotEmpty) {
          _transcriptMap[transcript.audioUrl] = transcript;
        }
      }
      
      _isLoaded = true;
      print('Loaded ${_transcriptMap.length} audio transcripts');
    } catch (e) {
      print('Error loading transcripts: $e');
      _transcriptMap.clear();
    }
  }

  /// Get transcript by audio URL
  /// Supports fuzzy matching by filename pattern
  AudioTranscript? getTranscriptByAudioUrl(String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return null;
    
    // Try exact match first
    if (_transcriptMap.containsKey(audioUrl)) {
      return _transcriptMap[audioUrl];
    }
    
    // Try fuzzy match by extracting filename pattern
    // Example: "96-I-listening/961_01.mp3" -> match any URL ending with this
    final normalizedInput = _normalizeUrl(audioUrl);
    
    for (var entry in _transcriptMap.entries) {
      final normalizedKey = _normalizeUrl(entry.key);
      if (normalizedKey == normalizedInput) {
        return entry.value;
      }
    }
    
    return null;
  }

  /// Normalize URL to get the unique identifier part
  /// Extracts exam_id/filename pattern (e.g., "96-I-listening/961_01.mp3")
  String _normalizeUrl(String url) {
    // Remove protocol and domain
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    
    // Get last 2 segments (folder/filename)
    if (pathSegments.length >= 2) {
      return '${pathSegments[pathSegments.length - 2]}/${pathSegments.last}';
    }
    
    return pathSegments.last;
  }

  /// Check if transcript exists for audio URL
  bool hasTranscript(String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return false;
    return _transcriptMap.containsKey(audioUrl);
  }

  /// Get total number of loaded transcripts
  int get transcriptCount => _transcriptMap.length;

  /// Check if transcripts are loaded
  bool get isLoaded => _isLoaded;
}
