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
      backgroundColor: AppConstants.uiDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstants.world1Secondary,
                  Color(0xFFEAF9FF),
                  Color(0xFF246A37),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
                painter: _BubbleBgPainter(_bgCtrl.value), child: Container()),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'BUBBLE BLITZ',
                      style: GoogleFonts.fredoka(
                        fontSize: 42,
                        height: 0.95,
                        color: AppConstants.foamWhite,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black45,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppConstants.bubbleOrange,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    'ARCADE',
                    style: GoogleFonts.fredoka(
                      color: AppConstants.uiDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 120.ms).scale(),
                const SizedBox(height: 8),
                Text(
                  'Log jumps. Bubble shots. Boss fights.',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: AppConstants.foamWhite.withValues(alpha: 0.88),
                    shadows: const [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black54,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _characterPreview(),
                const Spacer(),
                _menuButton(Icons.play_arrow_rounded, 'ARCADE START',
                    AppConstants.accentYellow, AppConstants.uiDark, () {
                  context.go('/levels');
                }),
                const SizedBox(height: 12),
                _menuButton(Icons.shopping_bag_rounded, 'AVATAR SHOP',
                    AppConstants.bubbleOrange, Colors.white, () {
                  context.go('/store');
                }),
                const SizedBox(height: 12),
                _menuButton(Icons.tune_rounded, 'OPTIONS', AppConstants.uiPanel,
                    AppConstants.foamWhite, () {
                  context.go('/settings');
                }),
                const SizedBox(height: 12),
                Text(
                  'Bits ${SaveService.instance.data.coins}   Best ${SaveService.instance.data.highScore}',
                  style: GoogleFonts.fredoka(
                    color: AppConstants.foamWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
        ? AppConstants.heroGreen
        : ch == CharacterType.phoenix
            ? AppConstants.fireRed
            : AppConstants.bubbleBlue;
    final accent = ch == CharacterType.phoenix
        ? AppConstants.foamWhite
        : AppConstants.accentYellow;
    return Column(
      children: [
        SizedBox(
          width: 218,
          height: 126,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 10,
                child: _heroToken(
                  color: color,
                  accent: accent,
                  glow: color,
                ),
              ),
              Positioned(
                right: 10,
                child: _heroToken(
                  color: AppConstants.bubbleOrange,
                  accent: AppConstants.foamWhite,
                  glow: AppConstants.bubbleOrange,
                ),
              ),
              Positioned(
                top: 10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppConstants.bubbleBlue.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _MenuBubblePainter(t: _bgCtrl.value),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .moveY(
              begin: 0,
              end: -8,
              duration: 1.4.seconds,
              curve: Curves.easeInOut,
            )
            .then()
            .moveY(
              begin: 0,
              end: 8,
              duration: 1.4.seconds,
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 8),
        Text(
          '${ch.displayName} + Red Dino',
          style: GoogleFonts.fredoka(
            color: AppConstants.foamWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                blurRadius: 6,
                color: Colors.black54,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroToken({
    required Color color,
    required Color accent,
    required Color glow,
  }) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: AppConstants.foamWhite.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size(96, 96),
        painter: _HeroPreviewPainter(color: color, accent: accent),
      ),
    );
  }

  Widget _menuButton(
    IconData icon,
    String label,
    Color color,
    Color foreground,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 250,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 8,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 19, fontWeight: FontWeight.w700),
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
    final cliff = Paint()..color = const Color(0xFFB88B66);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), cliff);

    final falls = Rect.fromLTWH(
        size.width * 0.22, 0, size.width * 0.56, size.height * 0.86);
    canvas.drawRect(
      falls,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Colors.white,
            AppConstants.waterfall,
            Color(0xFFC7F0FF),
            Colors.white,
          ],
        ).createShader(falls),
    );
    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (double x = falls.left + 16; x < falls.right; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x - 24, size.height * 0.78), streak);
    }

    for (final y in [size.height * 0.32, size.height * 0.49]) {
      _drawMenuLog(canvas, Rect.fromLTWH(0, y, size.width * 0.43, 19));
      _drawMenuLog(canvas,
          Rect.fromLTWH(size.width * 0.56, y + 20, size.width * 0.38, 19));
    }
    for (final x in [24.0, size.width - 38]) {
      _drawMenuPost(canvas, x, size);
    }

    final rand = math.Random(13);
    for (int i = 0; i < 20; i++) {
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final r = 8.0 + rand.nextDouble() * 24;
      final speed = 30 + rand.nextDouble() * 60;
      final y =
          (baseY - (t * speed * 12) % size.height + size.height) % size.height;
      canvas.drawCircle(
        Offset(baseX, y),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(baseX - r * 0.3, y - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.34),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFF2F8C36),
    );
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.765, size.width, 12),
        Paint()..color = AppConstants.moss);
  }

  void _drawMenuLog(Canvas canvas, Rect rect) {
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(r, Paint()..color = AppConstants.bark);
    canvas.drawRRect(
      r,
      Paint()
        ..color = AppConstants.barkDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 3, rect.top - 1, rect.width - 6, 6),
        const Radius.circular(4),
      ),
      Paint()..color = AppConstants.moss,
    );
    final vine = Paint()
      ..color = AppConstants.vine
      ..strokeWidth = 2;
    for (double x = rect.left + 20; x < rect.right; x += 38) {
      canvas.drawLine(
          Offset(x, rect.top - 2), Offset(x + 12, rect.bottom + 2), vine);
    }
  }

  void _drawMenuPost(Canvas canvas, double x, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height * 0.23, 14, size.height * 0.57),
        const Radius.circular(7),
      ),
      Paint()..color = AppConstants.bark,
    );
    final vine = Paint()
      ..color = AppConstants.vine
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double y = size.height * 0.26; y < size.height * 0.74; y += 70) {
      final path = Path()
        ..moveTo(x + 4, y)
        ..quadraticBezierTo(x + 19, y + 24, x + 5, y + 55);
      canvas.drawPath(path, vine);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleBgPainter old) => old.t != t;
}

class _MenuBubblePainter extends CustomPainter {
  final double t;
  const _MenuBubblePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final pulse = math.sin(t * math.pi * 2) * 2;
    canvas.drawCircle(
      c,
      size.width * 0.36 + pulse,
      Paint()
        ..color = AppConstants.bubbleBlue.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      Offset(c.dx - 8, c.dy - 9),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(covariant _MenuBubblePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _HeroPreviewPainter extends CustomPainter {
  final Color color;
  final Color accent;

  const _HeroPreviewPainter({required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 104;
    final sy = size.height / 104;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawOval(
      const Rect.fromLTWH(22, 88, 62, 9),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final tail = Path()
      ..moveTo(30, 66)
      ..quadraticBezierTo(6, 55, 22, 36)
      ..quadraticBezierTo(33, 50, 38, 68)
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = Color.lerp(color, AppConstants.uiDark, 0.2)!,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 37, 39, 50),
        const Radius.circular(20),
      ),
      Paint()..color = color,
    );
    canvas.drawOval(
      const Rect.fromLTWH(41, 54, 19, 27),
      Paint()..color = const Color(0xFFFFF5C6),
    );
    canvas.drawOval(
      const Rect.fromLTWH(27, 18, 55, 40),
      Paint()..color = color,
    );
    canvas.drawOval(
      const Rect.fromLTWH(65, 33, 25, 16),
      Paint()..color = const Color(0xFFFFF5C6),
    );

    final crest = Path()
      ..moveTo(36, 21)
      ..lineTo(42, 7)
      ..lineTo(48, 21)
      ..lineTo(54, 7)
      ..lineTo(60, 21);
    canvas.drawPath(
      crest,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = AppConstants.uiDark;
    canvas.drawOval(const Rect.fromLTWH(39, 25, 16, 22), white);
    canvas.drawOval(const Rect.fromLTWH(57, 25, 16, 22), white);
    canvas.drawCircle(const Offset(48, 36), 5, ink);
    canvas.drawCircle(const Offset(66, 36), 5, ink);
    canvas.drawCircle(const Offset(50, 33), 1.7, white);
    canvas.drawCircle(const Offset(68, 33), 1.7, white);

    canvas.drawArc(
      const Rect.fromLTWH(50, 44, 17, 9),
      0,
      3.14,
      false,
      Paint()
        ..color = AppConstants.uiDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (accent == AppConstants.foamWhite) {
      final mark = Paint()
        ..color = AppConstants.foamWhite.withValues(alpha: 0.85)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(35, 45), const Offset(57, 56), mark);
      canvas.drawLine(const Offset(40, 20), const Offset(70, 27), mark);
    }

    canvas.drawCircle(const Offset(27, 57), 9, Paint()..color = accent);
    canvas.drawCircle(const Offset(74, 58), 9, Paint()..color = accent);
    canvas.drawOval(
      const Rect.fromLTWH(32, 84, 17, 9),
      Paint()..color = Color.lerp(color, AppConstants.uiDark, 0.28)!,
    );
    canvas.drawOval(
      const Rect.fromLTWH(57, 84, 17, 9),
      Paint()..color = Color.lerp(color, AppConstants.uiDark, 0.28)!,
    );
    canvas.drawCircle(
      const Offset(86, 36),
      10,
      Paint()
        ..color = AppConstants.bubbleBlue.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeroPreviewPainter oldDelegate) {
    return color != oldDelegate.color || accent != oldDelegate.accent;
  }
}
