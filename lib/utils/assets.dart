class Assets {
  static const String _audio = 'assets/audio/';
  static const String _images = 'assets/images/';

  // Audio
  static const String bgm = '${_audio}bgm.wav';
  static const String sfxBubbleShoot = '${_audio}bubble_shoot.wav';
  static const String sfxBubblePop = '${_audio}bubble_pop.wav';
  static const String sfxCoinCollect = '${_audio}coin_collect.wav';
  static const String sfxPlayerHit = '${_audio}player_hit.wav';
  static const String sfxLevelComplete = '${_audio}level_complete.wav';
  static const String sfxGameOver = '${_audio}game_over.wav';

  // FlameAudio uses relative paths under assets/audio
  static const String flameBgm = 'bgm.wav';
  static const String flameBubbleShoot = 'bubble_shoot.wav';
  static const String flameBubblePop = 'bubble_pop.wav';
  static const String flameCoinCollect = 'coin_collect.wav';
  static const String flamePlayerHit = 'player_hit.wav';
  static const String flameLevelComplete = 'level_complete.wav';
  static const String flameGameOver = 'game_over.wav';

  // Images (paths kept for future sprite loading)
  static const String logo = '${_images}logo.png';
}
