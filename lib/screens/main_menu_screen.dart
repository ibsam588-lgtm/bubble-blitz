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
  late AnimationController _bobCtrl;
  BannerAd? _bannerAd;
  late int _selectedCharIdx;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 10))..repeat();
    _bobCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    AudioService.instance.playBgm();
    _bannerAd = AdsService.instance.createBannerAd();
    final saved = SaveService.instance.data.selectedChar;
    _selectedCharIdx = CharacterType.values.indexWhere((c) => c.id == saved);
    if (_selectedCharIdx < 0) _selectedCharIdx = 0;
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _bobCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  CharacterType get _selectedChar => CharacterType.values[_selectedCharIdx];

  void _selectChar(int idx) {
    final ch = CharacterType.values[idx];
    if (!SaveService.instance.data.unlockedChars.contains(ch.id)) return;
    setState(() => _selectedCharIdx = idx);
    SaveService.instance.data.selectedChar = ch.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Jungle background painter
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _JungleBgPainter(_bgCtrl.value),
              child: Container(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                // Title
                _buildTitle(),
                const SizedBox(height: 8),
                Text(
                  'Pop. Trap. Conquer.',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    color: Colors.white70,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
                const Spacer(),
                // Bobbing character preview
                _buildCharPreview(),
                const SizedBox(height: 12),
                // Character selector dots
                _buildCharDots(),
                const Spacer(),
                // Buttons
                _gradientButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFF43A047), Color(0xFF1B5E20)],
                  onTap: () => context.go('/levels'),
                ),
                const SizedBox(height: 12),
                _gradientButton(
                  label: 'STORE',
                  icon: Icons.store_rounded,
                  colors: const [Color(0xFFFF9800), Color(0xFFE65100)],
                  onTap: () => context.go('/store'),
                ),
                const SizedBox(height: 12),
                _gradientButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_rounded,
                  colors: const [Color(0xFF00838F), Color(0xFF004D40)],
                  onTap: () => context.go('/settings'),
                ),
                const SizedBox(height: 16),
                // Stats bar
                _buildStatsBar(),
                if (_bannerAd != null)
                  SizedBox(height: 50, child: AdWidget(ad: _bannerAd!))
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Bubble Blitz',
      style: GoogleFonts.fredoka(
        fontSize: 58,
        foreground: Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF76FF03), Color(0xFFFFEB3B)],
          ).createShader(const Rect.fromLTWH(0, 0, 300, 60)),
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(-3, -3), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(3, -3), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(-3, 3), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }

  Widget _buildCharPreview() {
    final ch = _selectedChar;
    return AnimatedBuilder(
      animation: _bobCtrl,
      builder: (_, __) {
        final dy = (_bobCtrl.value - 0.5) * 16;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Column(
            children: [
              // Glow halo behind character
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _charColor(ch).withValues(alpha: 0.55),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  // Canvas-drawn Bub dragon
                  CustomPaint(
                    size: const Size(90, 90),
                    painter: _BubPreviewPainter(ch),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ch.displayName,
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 22,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(CharacterType.values.length, (i) {
        final ch = CharacterType.values[i];
        final unlocked =
            SaveService.instance.data.unlockedChars.contains(ch.id);
        final selected = i == _selectedCharIdx;
        return GestureDetector(
          onTap: unlocked ? () => _selectChar(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: selected ? 18 : 12,
            height: selected ? 18 : 12,
            decoration: BoxDecoration(
              color: unlocked ? _charColor(ch) : Colors.white30,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: selected
                  ? [BoxShadow(color: _charColor(ch).withValues(alpha: 0.6), blurRadius: 8)]
                  : null,
            ),
            child: unlocked ? null : const Icon(Icons.lock, size: 7, color: Colors.white54),
          ),
        );
      }),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.55),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final data = SaveService.instance.data;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('🪙', '${data.coins}', AppConstants.accentYellow),
          Container(width: 1, height: 24, color: Colors.white24),
          _statItem('⭐', '${data.highScore}', const Color(0xFFFFD600)),
        ],
      ),
    );
  }

  Widget _statItem(String icon, String value, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.fredoka(color: color, fontSize: 18,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 3)]),
        ),
      ],
    );
  }

  Color _charColor(CharacterType ch) {
    switch (ch) {
      case CharacterType.dragon:  return const Color(0xFF4CAF50);
      case CharacterType.phoenix: return const Color(0xFFFF5722);
      case CharacterType.shadow:  return const Color(0xFF7E57C2);
    }
  }
}

// ── Jungle background painter ─────────────────────────────────────────────────

class _JungleBgPainter extends CustomPainter {
  final double t;
  _JungleBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF66BB6A)],
          stops: [0.0, 0.4, 1.0],
        ).createShader(rect),
    );

    // Rolling hills
    _drawHill(canvas, w, h, 0.5, const Color(0xFF1B5E20));
    _drawHill(canvas, w, h, 0.64, const Color(0xFF2E7D32));
    _drawHill(canvas, w, h, 0.78, const Color(0xFF388E3C));

    // Bamboo stalks silhouettes
    for (final x in [0.06, 0.14, 0.82, 0.90, 0.95]) {
      _drawBambooSilhouette(canvas, w * x, h * 0.3, h * 0.8, w);
    }

    // Animated floating bubbles
    final rand = math.Random(13);
    for (int i = 0; i < 20; i++) {
      final bx = rand.nextDouble() * w;
      final by = rand.nextDouble() * h;
      final r = 8.0 + rand.nextDouble() * 20;
      final speed = 25 + rand.nextDouble() * 55;
      final y = (by - (t * speed * 10) % h + h) % h;

      // Bubble with inner glow
      canvas.drawCircle(Offset(bx, y), r,
          Paint()..color = Colors.white.withValues(alpha: 0.12));
      canvas.drawCircle(
        Offset(bx, y), r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      // Highlight dot
      canvas.drawCircle(
        Offset(bx - r * 0.3, y - r * 0.3), r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  void _drawHill(Canvas canvas, double w, double h, double yFrac, Color color) {
    final baseY = h * yFrac;
    final path = Path()..moveTo(0, h);
    const steps = 8;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final y = baseY + math.sin(i * 0.9 + 0.5) * 35;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBambooSilhouette(
      Canvas canvas, double x, double yTop, double yBot, double w) {
    canvas.drawRect(
      Rect.fromLTWH(x - 7, yTop, 14, yBot - yTop),
      Paint()..color = const Color(0xFF1B5E20).withValues(alpha: 0.6),
    );
    for (double y = yTop + 18; y < yBot; y += 22) {
      canvas.drawRect(
        Rect.fromLTWH(x - 9, y, 18, 3),
        Paint()..color = const Color(0xFF0D3A0D).withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JungleBgPainter old) => old.t != t;
}

// ── Bub preview painter ───────────────────────────────────────────────────────

class _BubPreviewPainter extends CustomPainter {
  final CharacterType character;
  _BubPreviewPainter(this.character);

  Color get _bodyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF4CAF50);
      case CharacterType.phoenix: return const Color(0xFFFF5722);
      case CharacterType.shadow:  return const Color(0xFF4527A0);
    }
  }

  Color get _bellyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF81C784);
      case CharacterType.phoenix: return const Color(0xFFFFCC02);
      case CharacterType.shadow:  return const Color(0xFF9575CD);
    }
  }

  Color get _outlineColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF1B5E20);
      case CharacterType.phoenix: return const Color(0xFFBF360C);
      case CharacterType.shadow:  return const Color(0xFF1A237E);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 36.0; // scale factor

    canvas.save();
    canvas.translate(cx - 18 * s, cy - 20 * s);
    canvas.scale(s, s);

    // Wing nub
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(5, 17), width: 17, height: 12),
      Paint()..color = _bodyColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(5, 17), width: 17, height: 12),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Body
    canvas.drawOval(Rect.fromLTWH(2, 5, 32, 32), Paint()..color = _bodyColor);
    canvas.drawOval(
      Rect.fromLTWH(2, 5, 32, 32),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(18, 25), width: 19, height: 21),
      Paint()..color = _bellyColor,
    );

    // Horn
    final hornPath = Path()
      ..moveTo(22, 8)
      ..lineTo(26, 0)
      ..lineTo(30, 8)
      ..close();
    canvas.drawPath(hornPath, Paint()..color = _outlineColor);

    // Eye
    canvas.drawCircle(const Offset(25, 15), 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      const Offset(25, 15), 6.5,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(const Offset(27, 15.5), 3.8, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(24, 11.5), 1.5, Paint()..color = Colors.white);

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 35, 12, 5), Radius.circular(3)),
      Paint()..color = _outlineColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(20, 35, 12, 5), Radius.circular(3)),
      Paint()..color = _outlineColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubPreviewPainter old) =>
      old.character != character;
}
