import 'package:audioplayers/audioplayers.dart';
import '../constants/app_sounds.dart';

/// Audio service with pre-loaded pool for low-latency playback.
/// Creates a separate AudioPlayer per sound to allow concurrent playback.
class AudioService {
  AudioService._();

  static final _pool = <String, AudioPlayer>{};
  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Call once at app start. Pre-loads all audio assets.
  static Future<void> initialize() async {
    for (final path in AppSounds.all) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);
      _pool[path] = player;
    }
  }

  /// Play a sound asset. Stops and restarts for rapid re-triggering.
  static Future<void> play(String assetPath, {double volume = 1.0}) async {
    if (!_enabled) return;
    final player = _pool[assetPath];
    if (player == null) return;
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Silent fail — missing audio file during development
    }
  }

  static Future<void> dispose() async {
    for (final player in _pool.values) {
      await player.dispose();
    }
    _pool.clear();
  }
}
