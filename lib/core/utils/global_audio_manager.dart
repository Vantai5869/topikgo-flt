import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Global Audio Manager (Singleton)
/// Ensures only one audio plays at a time across the app
class GlobalAudioManager extends ChangeNotifier {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;

  GlobalAudioManager._internal() {
    _player = AudioPlayer();

    // Don't configure anything - use defaults like exam screen
    // This matches the fast-loading exam screen implementation

    _player.onPlayerStateChanged.listen((state) {
      _state = state;
      notifyListeners();
    });

    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
  }

  late final AudioPlayer _player;
  String? _currentUrl;
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String? get currentUrl => _currentUrl;
  PlayerState get state => _state;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _state == PlayerState.playing;

  Future<void> play(String url) async {
    if (_currentUrl == url) {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else if (_state == PlayerState.completed) {
        // Audio finished - just play again from same source
        // Don't stop() - it releases resources and causes delay
        _duration = Duration.zero;
        _position = Duration.zero;
        await _player.play(UrlSource(url));
      } else {
        await _player.resume();
      }
    } else {
      // Different URL - stop and switch
      await _player.stop();
      _currentUrl = url;
      _duration = Duration.zero;
      _position = Duration.zero;
      await _player.play(UrlSource(url));
    }
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentUrl = null;
    notifyListeners();
  }

  Future<void> seek(Duration p) async {
    await _player.seek(p);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
