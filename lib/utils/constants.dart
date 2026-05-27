import 'dart:io';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Bubble Blitz';
  static const String appVersion = '1.0.0';

  // World colors
  static const Color world1Primary = Color(0xFFFFB6C1); // candy pink
  static const Color world1Secondary = Color(0xFFFFF59D); // pastel yellow
  static const Color world2Primary = Color(0xFF1B5E20); // dark green
  static const Color world2Secondary = Color(0xFF0D47A1); // dark blue
  static const Color world3Primary = Color(0xFFD32F2F); // red
  static const Color world3Secondary = Color(0xFFFF6F00); // orange

  // UI colors
  static const Color bubbleBlue = Color(0xFF40C4FF);
  static const Color bubbleOrange = Color(0xFFFF9800);
  static const Color bubblePurple = Color(0xFF9C27B0);
  static const Color accentYellow = Color(0xFFFFEB3B);
  static const Color uiDark = Color(0xFF1A1A2E);
  static const Color uiCard = Color(0xFF16213E);

  // Game tuning
  static const double playerSpeed = 180.0;
  static const double playerJumpVelocity = -420.0;
  static const double gravity = 980.0;
  static const double bubbleSpeed = 280.0;
  static const double bubbleLifetime = 3.0;
  static const double trappedBubbleRise = -40.0;

  // Store costs (coins)
  static const int characterPhoenixCost = 500;
  static const int characterShadowCost = 1000;
  static const int shieldPackCost = 100;
  static const int speedPackCost = 80;
  static const int multiBubblePackCost = 120;
  static const int extraLife1Cost = 50;
  static const int extraLife5Cost = 200;
  static const int continueCost = 50;
}

class AdMobIds {
  // TODO: replace with real AdMob IDs after setup
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Google test banner
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Google test rewarded
      : 'ca-app-pub-3940256099942544/1712485313';

  static const String appId =
      'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'; // TODO: replace
}

class IapIds {
  static const String coinpackStarter = 'coinpack_starter';
  static const String coinpackValue = 'coinpack_value';
  static const String coinpackMega = 'coinpack_mega';
  static const String removeAds = 'remove_ads';

  static const Set<String> all = {
    coinpackStarter,
    coinpackValue,
    coinpackMega,
    removeAds,
  };
}

class SaveKeys {
  static const String coins = 'coins';
  static const String highScore = 'high_score';
  static const String unlockedChars = 'unlocked_chars';
  static const String selectedChar = 'selected_char';
  static const String unlockedLevels = 'unlocked_levels';
  static const String levelStars = 'level_stars';
  static const String musicEnabled = 'music_enabled';
  static const String sfxEnabled = 'sfx_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String adsRemoved = 'ads_removed';
  static const String shields = 'shields';
  static const String speedBoosts = 'speed_boosts';
  static const String multiBubbles = 'multi_bubbles';
  static const String extraLives = 'extra_lives';
}
