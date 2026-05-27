import 'package:flame_audio/flame_audio.dart';
import '../utils/assets.dart';
import 'save_service.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  bool _initialized = false;
  bool _bgmPlaying = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await FlameAudio.audioCache.loadAll([
        Assets.flameBubbleShoot,
        Assets.flameBubblePop,
        Assets.flameCoinCollect,
        Assets.flamePlayerHit,
        Assets.flameLevelComplete,
        Assets.flameGameOver,
      ]);
    } catch (_) {
      // Graceful no-op if assets missing
    }
  }

  Future<void> playBgm() async {
    if (!SaveService.instance.musicEnabled) return;
    if (_bgmPlaying) return;
    try {
      await FlameAudio.bgm.play(Assets.flameBgm, volume: 0.4);
      _bgmPlaying = true;
    } catch (_) {
      _bgmPlaying = false;
    }
  }

  Future<void> stopBgm() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
    _bgmPlaying = false;
  }

  Future<void> playSfx(String name) async {
    if (!SaveService.instance.sfxEnabled) return;
    try {
      await FlameAudio.play(name, volume: 0.7);
    } catch (_) {}
  }

  Future<void> refreshFromSettings() async {
    if (SaveService.instance.musicEnabled) {
      await playBgm();
    } else {
      await stopBgm();
    }
  }
}
