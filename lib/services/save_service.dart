import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';
import '../utils/constants.dart';

class SaveService {
  static SaveService? _instance;
  static SaveService get instance => _instance ??= SaveService._();
  SaveService._();

  SharedPreferences? _prefs;
  PlayerData _data = PlayerData();
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _vibrationEnabled = true;
  bool _adsRemoved = false;

  PlayerData get data => _data;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get adsRemoved => _adsRemoved;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _data = PlayerData(
      coins: _prefs?.getInt(SaveKeys.coins) ?? 0,
      highScore: _prefs?.getInt(SaveKeys.highScore) ?? 0,
      unlockedChars:
          _prefs?.getStringList(SaveKeys.unlockedChars) ?? ['dragon'],
      selectedChar: _prefs?.getString(SaveKeys.selectedChar) ?? 'dragon',
      unlockedLevels: _prefs?.getInt(SaveKeys.unlockedLevels) ?? 1,
      levelStars: _loadLevelStars(),
      shields: _prefs?.getInt(SaveKeys.shields) ?? 0,
      speedBoosts: _prefs?.getInt(SaveKeys.speedBoosts) ?? 0,
      multiBubbles: _prefs?.getInt(SaveKeys.multiBubbles) ?? 0,
      extraLives: _prefs?.getInt(SaveKeys.extraLives) ?? 0,
    );
    _musicEnabled = _prefs?.getBool(SaveKeys.musicEnabled) ?? true;
    _sfxEnabled = _prefs?.getBool(SaveKeys.sfxEnabled) ?? true;
    _vibrationEnabled = _prefs?.getBool(SaveKeys.vibrationEnabled) ?? true;
    _adsRemoved = _prefs?.getBool(SaveKeys.adsRemoved) ?? false;
  }

  Map<int, int> _loadLevelStars() {
    final list = _prefs?.getStringList(SaveKeys.levelStars) ?? const [];
    final Map<int, int> stars = {};
    for (final raw in list) {
      final parts = raw.split(':');
      if (parts.length == 2) {
        final level = int.tryParse(parts[0]);
        final s = int.tryParse(parts[1]);
        if (level != null && s != null) stars[level] = s;
      }
    }
    return stars;
  }

  Future<void> saveCoins(int coins) async {
    _data.coins = coins;
    await _prefs?.setInt(SaveKeys.coins, coins);
  }

  Future<void> addCoins(int amount) async {
    await saveCoins(_data.coins + amount);
  }

  Future<bool> spendCoins(int amount) async {
    if (_data.coins < amount) return false;
    await saveCoins(_data.coins - amount);
    return true;
  }

  Future<void> saveHighScore(int score) async {
    if (score > _data.highScore) {
      _data.highScore = score;
      await _prefs?.setInt(SaveKeys.highScore, score);
    }
  }

  Future<void> unlockCharacter(String id) async {
    if (!_data.unlockedChars.contains(id)) {
      _data.unlockedChars.add(id);
      await _prefs?.setStringList(SaveKeys.unlockedChars, _data.unlockedChars);
    }
  }

  Future<void> setSelectedCharacter(String id) async {
    _data.selectedChar = id;
    await _prefs?.setString(SaveKeys.selectedChar, id);
  }

  Future<void> unlockLevel(int level) async {
    if (level > _data.unlockedLevels) {
      _data.unlockedLevels = level;
      await _prefs?.setInt(SaveKeys.unlockedLevels, level);
    }
  }

  Future<void> setLevelStars(int level, int stars) async {
    final current = _data.levelStars[level] ?? 0;
    if (stars > current) {
      _data.levelStars[level] = stars;
      final list = _data.levelStars.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      await _prefs?.setStringList(SaveKeys.levelStars, list);
    }
  }

  Future<void> setMusicEnabled(bool v) async {
    _musicEnabled = v;
    await _prefs?.setBool(SaveKeys.musicEnabled, v);
  }

  Future<void> setSfxEnabled(bool v) async {
    _sfxEnabled = v;
    await _prefs?.setBool(SaveKeys.sfxEnabled, v);
  }

  Future<void> setVibrationEnabled(bool v) async {
    _vibrationEnabled = v;
    await _prefs?.setBool(SaveKeys.vibrationEnabled, v);
  }

  Future<void> setAdsRemoved(bool v) async {
    _adsRemoved = v;
    await _prefs?.setBool(SaveKeys.adsRemoved, v);
  }

  Future<void> addShields(int n) async {
    _data.shields += n;
    await _prefs?.setInt(SaveKeys.shields, _data.shields);
  }

  Future<void> addSpeedBoosts(int n) async {
    _data.speedBoosts += n;
    await _prefs?.setInt(SaveKeys.speedBoosts, _data.speedBoosts);
  }

  Future<void> addMultiBubbles(int n) async {
    _data.multiBubbles += n;
    await _prefs?.setInt(SaveKeys.multiBubbles, _data.multiBubbles);
  }

  Future<void> addExtraLives(int n) async {
    _data.extraLives += n;
    await _prefs?.setInt(SaveKeys.extraLives, _data.extraLives);
  }

  Future<bool> useExtraLife() async {
    if (_data.extraLives <= 0) return false;
    _data.extraLives -= 1;
    await _prefs?.setInt(SaveKeys.extraLives, _data.extraLives);
    return true;
  }
}
