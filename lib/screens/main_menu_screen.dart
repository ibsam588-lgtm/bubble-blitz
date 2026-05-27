import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/player_data.dart';
import '../services/ads_service.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    AudioService.instance.playBgm();
    _bannerAd = AdsService.instance.createBannerAd();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  CharacterType get selected {
    final id = SaveService.instance.data.selectedChar;
    return CharacterType.values.firstWhere(
      (c) => c.id == id,
      orElse: () => CharacterType.dragon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppConstants.bubbleBlue, AppConstants.bubblePurple],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) =>
                CustomPaint(painter: _BubbleBgPainter(_bgCtrl.value), child: Container()),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  'Bubble Blitz',
                  style: GoogleFonts.fredoka(
                    fontSize: 56,
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(2, 4)),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(),
                const SizedBox(height: 12),
                Text(
                  'Pop. Trap. Conquer.',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                _characterPreview(),
                const Spacer(),
                _menuButton('PLAY', AppConstants.accentYellow, () {
                  context.go('/levels');
                }),
                const SizedBox(height: 14),
                _menuButton('STORE', AppConstants.bubbleOrange, () {
                  context.go('/store');
                }),
                const SizedBox(height: 14),
                _menuButton('SETTINGS', Colors.white24, () {
                  context.go('/settings');
                }),
                const SizedBox(height: 14),
                Text(
                  'Coins: ${SaveService.instance.data.coins} 🪙   Hi: ${SaveService.instance.data.highScore}',
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14),
                ),
                if (_bannerAd != null)
                  SizedBox(
                    height: 50,
                    child: AdWidget(ad: _bannerAd!),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _characterPreview() {
    final ch = selected;
    final color = ch == CharacterType.dragon
        ? AppConstants.bubbleBlue
        : ch == CharacterType.phoenix
            ? AppConstants.bubbleOrange
            : AppConstants.bubblePurple;
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(ch.emoji, style: const TextStyle(fontSize: 64)),
        ).animate(onPlay: (c) => c.repeat()).moveY(begin: 0, end: -8, duration: 1.4.seconds, curve: Curves.easeInOut).then().moveY(begin: 0, end: 8, duration: 1.4.seconds, curve: Curves.easeInOut),
        const SizedBox(height: 8),
        Text(
          ch.displayName,
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20),
        ),
      ],
    );
  }

  Widget _menuButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 6,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 22),
        ),
      ),
    );
  }
}

class _BubbleBgPainter extends CustomPainter {
  final double t;
  _BubbleBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(13);
    for (int i = 0; i < 24; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final r = 8.0 + rand.nextDouble() * 24;
      final speed = 30 + rand.nextDouble() * 60;
      final y = (baseY - (t * speed * 12) % size.height + size.height) % size.height;
      canvas.drawCircle(
        Offset(baseX, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
      canvas.drawCircle(
        Offset(baseX - r * 0.3, y - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleBgPainter old) => old.t != t;
}
