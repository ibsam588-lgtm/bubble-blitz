import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Bubble Blitz';
  static const String appVersion = '1.0.0+1';

  // World colors
  static const Color world1Primary = Color(0xFF5FA448); // waterfall moss
  static const Color world1Secondary = Color(0xFFC8ECFF); // waterfall mist
  static const Color world2Primary = Color(0xFF5EAF38); // forest grass
  static const Color world2Secondary = Color(0xFF6EC8FF); // mountain sky
  static const Color world3Primary = Color(0xFF6B4A31); // bark arena
  static const Color world3Secondary = Color(0xFF22496A); // dusk canopy

  // UI colors
  static const Color bubbleBlue = Color(0xFF3FCBFF);
  static const Color bubbleOrange = Color(0xFFE84A30);
  static const Color bubblePurple = Color(0xFF7246B6);
  static const Color heroGreen = Color(0xFF48C64A);
  static const Color accentYellow = Color(0xFFFFD54A);
  static const Color foamWhite = Color(0xFFFFFFFF);
  static const Color uiDark = Color(0xFF102033);
  static const Color uiCard = Color(0xFF173B4F);
  static const Color uiPanel = Color(0xFF245C56);
  static const Color bark = Color(0xFFB88B46);
  static const Color barkDark = Color(0xFF5E3A22);
  static const Color moss = Color(0xFF2FB85D);
  static const Color vine = Color(0xFF287D36);
  static const Color waterfall = Color(0xFFDDF8FF);
  static const Color fireRed = Color(0xFFE64222);

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
  static const String appId = 'ca-app-pub-8127360916614638~9122968705';

  static String get bannerAdUnitId => 'ca-app-pub-8127360916614638/7047165781';

  static String get rewardedAdUnitId =>
      'ca-app-pub-8127360916614638/5016202735';

  static String get interstitialAdUnitId =>
      'ca-app-pub-8127360916614638/3870642029';
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
