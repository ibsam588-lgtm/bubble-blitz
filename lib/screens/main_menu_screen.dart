import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _bobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    AudioService.instance.playBgm();
    _bannerAd = AdsService.instance.createBannerAd();
    final saved = SaveService.instance.data.selectedChar;
    _selectedCharIdx =
        CharacterType.values.indexWhere((c) => c.id == saved);
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

  Future<void> _confirmExitApp() async {
    final leave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        title: Text(
          'Quit Bubble Blitz?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 26),
        ),
        content: Text(
          'Are you sure you want to exit the game?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: Text('STAY', style: GoogleFonts.fredoka(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('EXIT', style: GoogleFonts.fredoka(fontSize: 18)),
          ),
        ],
      ),
    );
    if (leave == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmExitApp();
      },
      child: Scaffold(
      body: Stack(
        children: [
          // ── Cave background ─────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _CaveBgPainter(_bgCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────────────
                _buildTitle(),
                const SizedBox(height: 4),
                Text(
                  'Pop. Trap. Conquer.',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),

                const Spacer(),

                // ── Bobbing character preview ──────────────────────────────
                _buildCharPreview(),
                const SizedBox(height: 10),
                _buildCharDots(),

                const Spacer(),

                // ── Menu buttons ───────────────────────────────────────────
                _gradientButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  colors: const [Color(0xFF00C853), Color(0xFF004D20)],
                  onTap: () => context.go('/levels'),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 10),
                _gradientButton(
                  label: 'STORE',
                  icon: Icons.storefront_rounded,
                  colors: const [Color(0xFFFF6F00), Color(0xFF4A1A00)],
                  onTap: () => context.go('/store'),
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.2),
                const SizedBox(height: 10),
                _gradientButton(
                  label: 'SETTINGS',
                  icon: Icons.settings_rounded,
                  colors: const [Color(0xFF006064), Color(0xFF001A1C)],
                  onTap: () => context.go('/settings'),
                ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.2),

                const SizedBox(height: 14),
                _buildStatsBar(),

                if (_bannerAd != null)
                  SizedBox(height: 50, child: AdWidget(ad: _bannerAd!))
                else
                  const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTitle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind title
        Container(
          width: 300,
          height: 70,
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Color(0x4400E5FF), blurRadius: 40, spreadRadius: 10),
            ],
          ),
        ),
        Text(
          'BUBBLE BLITZ',
          style: GoogleFonts.fredoka(
            fontSize: 46,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFFFFEB3B), Color(0xFF00FF80)],
                stops: [0.0, 0.5, 1.0],
              ).createShader(const Rect.fromLTWH(0, 0, 340, 55)),
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(-3, -3)),
              Shadow(color: Colors.black, offset: Offset(3, -3)),
              Shadow(color: Colors.black, offset: Offset(-3, 3)),
              Shadow(color: Colors.black, offset: Offset(3, 3)),
              Shadow(color: Color(0x8800E5FF), offset: Offset(0, 4), blurRadius: 8),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).scale(
            begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildCharPreview() {
    final ch = _selectedChar;
    return AnimatedBuilder(
      animation: _bobCtrl,
      builder: (_, __) {
        final dy = (_bobCtrl.value - 0.5) * 14;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow halo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _charColor(ch).withValues(alpha: 0.5),
                          blurRadius: 36,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: const Size(96, 96),
                    painter: _BubPreviewPainter(ch),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _charColor(ch).withValues(alpha: 0.6), width: 1.5),
                ),
                child: Text(
                  ch.displayName.toUpperCase(),
                  style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4)
                      ]),
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
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: selected ? 20 : 13,
            height: selected ? 20 : 13,
            decoration: BoxDecoration(
              color: unlocked ? _charColor(ch) : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: _charColor(ch).withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 2)
                    ]
                  : null,
            ),
            child: unlocked
                ? null
                : const Icon(Icons.lock, size: 7, color: Colors.white54),
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
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
              color: colors.first.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                color: Colors.white,
                letterSpacing: 1,
                shadows: const [
                  Shadow(color: Colors.black38, blurRadius: 4)
                ],
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
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1.5),
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
          style: GoogleFonts.fredoka(
              color: color,
              fontSize: 18,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 3)]),
        ),
      ],
    );
  }

  Color _charColor(CharacterType ch) {
    switch (ch) {
      case CharacterType.dragon:  return const Color(0xFF2EC05C);
      case CharacterType.phoenix: return const Color(0xFF00B8D9);
      case CharacterType.shadow:  return const Color(0xFFE91E8C);
    }
  }
}

// ── Cave background painter ───────────────────────────────────────────────────

class _CaveBgPainter extends CustomPainter {
  final double t;
  _CaveBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // ── Deep cave gradient ──────────────────────────────────────────────
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF040810),
            Color(0xFF080F1C),
            Color(0xFF0D1A28),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // ── Stone wall tiles (left & right) ───────────────────────────────
    _drawWall(canvas, 0, 0, 30, h);
    _drawWall(canvas, w - 30, 0, 30, h);

    // ── Distant cave depth layers ──────────────────────────────────────
    for (int layer = 0; layer < 3; layer++) {
      final alpha = 0.06 + layer * 0.04;
      final yBase = h * (0.4 + layer * 0.18);
      _drawCaveStalagmites(canvas, w, yBase, layer, alpha);
    }

    // ── Stalactites from ceiling ───────────────────────────────────────
    final sRand = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final sx = sRand.nextDouble() * w;
      final sLen = 20 + sRand.nextDouble() * 50;
      _drawStalactite(canvas, sx, 0, sLen);
    }

    // ── Animated bubbles floating upward ──────────────────────────────
    final bRand = math.Random(99);
    for (int i = 0; i < 18; i++) {
      final bx = bRand.nextDouble() * w;
      final baseY = bRand.nextDouble() * h;
      final speed = 18 + bRand.nextDouble() * 40;
      final r = 6 + bRand.nextDouble() * 18;
      final y = (baseY - (t * speed * 10) % h + h) % h;
      final col = _bubbleColors[i % _bubbleColors.length];

      canvas.drawCircle(
          Offset(bx, y), r, Paint()..color = col.withValues(alpha: 0.08));
      canvas.drawCircle(
          Offset(bx, y),
          r,
          Paint()
            ..color = col.withValues(alpha: 0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);
      canvas.drawCircle(
          Offset(bx - r * 0.3, y - r * 0.3),
          r * 0.2,
          Paint()..color = Colors.white.withValues(alpha: 0.35));
    }

    // ── Torch flicker glow on cave walls ──────────────────────────────
    for (final tx in [32.0, w - 32.0]) {
      final flicker = (math.sin(t * 24 + tx) + 1) / 2;
      final torchY = h * 0.35;
      canvas.drawCircle(
        Offset(tx, torchY),
        22 + flicker * 8,
        Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.18 + flicker * 0.12),
      );
      // Torch stick
      canvas.drawRect(
        Rect.fromCenter(center: Offset(tx, torchY + 18), width: 6, height: 20),
        Paint()..color = const Color(0xFF5D4037),
      );
      // Flame
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(tx + math.sin(t * 20) * 3, torchY - 4),
            width: 10,
            height: 14 + flicker * 4),
        Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.85),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(tx, torchY - 4),
            width: 6,
            height: 8 + flicker * 3),
        Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.9),
      );
    }

    // ── Drip drops ────────────────────────────────────────────────────
    final dRand = math.Random(31);
    for (int i = 0; i < 10; i++) {
      final dx = 35 + dRand.nextDouble() * (w - 70);
      final speed = 50 + dRand.nextDouble() * 70;
      final dy = ((t * speed * 10 + i * 80) % h);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, dy), width: 3, height: 6),
        Paint()
          ..color = const Color(0xFF90CAF9).withValues(alpha: 0.4),
      );
    }

    // ── Bottom floor stone ────────────────────────────────────────────
    _drawWall(canvas, 0, h - 28, w, 28);
  }

  static const _bubbleColors = [
    Color(0xFF00E5FF),
    Color(0xFF76FF03),
    Color(0xFFFFEB3B),
    Color(0xFFFF6D00),
    Color(0xFFE040FB),
  ];

  void _drawWall(Canvas canvas, double x, double y, double w, double h) {
    const tileW = 26.0;
    const tileH = 20.0;
    for (double ty = y; ty < y + h; ty += tileH) {
      final row = ((ty - y) / tileH).floor();
      final xOff = (row % 2 == 0) ? 0.0 : tileW / 2;
      for (double tx = x - xOff; tx < x + w; tx += tileW) {
        final bx = tx.clamp(x, x + w - 1);
        final bw = (tx + tileW).clamp(x, x + w) - bx;
        if (bw <= 0) continue;
        final shade = 0.5 + ((tx * 5 + ty * 11).toInt().abs() % 25) / 100.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bx + 1, ty + 1, bw - 2, tileH - 2),
              const Radius.circular(2)),
          Paint()
            ..color = Color.fromARGB(255, (72 * shade).toInt(),
                (82 * shade).toInt(), (95 * shade).toInt()),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bx, ty, bw, tileH), const Radius.circular(2)),
          Paint()
            ..color = const Color(0xFF04080E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  void _drawCaveStalagmites(
      Canvas canvas, double w, double baseY, int layer, double alpha) {
    final rand = math.Random(layer * 13);
    for (int i = 0; i < 6 + layer * 2; i++) {
      final sx = rand.nextDouble() * w;
      final sw = 12 + rand.nextDouble() * 20;
      final sh = 20 + rand.nextDouble() * 50;
      canvas.drawPath(
        Path()
          ..moveTo(sx - sw / 2, baseY)
          ..lineTo(sx, baseY - sh)
          ..lineTo(sx + sw / 2, baseY)
          ..close(),
        Paint()
          ..color = Color.fromARGB(
              (alpha * 255).toInt(), 40, 55, 70),
      );
    }
  }

  void _drawStalactite(
      Canvas canvas, double x, double ceilY, double len) {
    canvas.drawPath(
      Path()
        ..moveTo(x - 5, ceilY)
        ..lineTo(x + 5, ceilY)
        ..lineTo(x, ceilY + len)
        ..close(),
      Paint()..color = const Color(0xFF1E2D3A),
    );
    canvas.drawCircle(
        Offset(x, ceilY + len), 2.0,
        Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(covariant _CaveBgPainter old) => old.t != t;
}

// ── BB2-style Bub preview painter ─────────────────────────────────────────────

class _BubPreviewPainter extends CustomPainter {
  final CharacterType character;
  _BubPreviewPainter(this.character);

  Color get _bodyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF2EC05C);
      case CharacterType.phoenix: return const Color(0xFF00B8D9);
      case CharacterType.shadow:  return const Color(0xFFE91E8C);
    }
  }

  Color get _bellyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFFA8E6C3);
      case CharacterType.phoenix: return const Color(0xFFB2EBF2);
      case CharacterType.shadow:  return const Color(0xFFF8BBD9);
    }
  }

  Color get _outlineColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF0A4020);
      case CharacterType.phoenix: return const Color(0xFF00405A);
      case CharacterType.shadow:  return const Color(0xFF5A0030);
    }
  }

  Color get _irisColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF00D4A0);
      case CharacterType.phoenix: return const Color(0xFF00D0F0);
      case CharacterType.shadow:  return const Color(0xFFFF70CC);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width / 42.0;

    canvas.save();
    canvas.translate(cx - 21 * s, cy - 21 * s);
    canvas.scale(s, s);

    // ── Round body ──
    canvas.drawCircle(const Offset(21, 22), 17, Paint()..color = _bodyColor);
    canvas.drawCircle(const Offset(21, 22), 17,
        Paint()
          ..color = _outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);

    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(21, 26), width: 20, height: 16),
      Paint()..color = _bellyColor,
    );

    // ── Horn ──
    final hornPath = Path()
      ..moveTo(24, 7)
      ..quadraticBezierTo(32, -4, 33, 5)
      ..lineTo(27, 7)
      ..close();
    canvas.drawPath(hornPath, Paint()..color = _outlineColor);

    // ── Front arm nub ──
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 24), width: 11, height: 9),
      Paint()..color = _bodyColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(36, 24), width: 11, height: 9),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── HUGE eye ──
    canvas.drawCircle(const Offset(27, 18), 10, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(27, 18), 10,
        Paint()
          ..color = _outlineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    // Iris
    canvas.drawCircle(const Offset(28.5, 19), 6.2,
        Paint()..color = _irisColor);
    // Pupil
    canvas.drawCircle(
        const Offset(29, 19.5), 3.6, Paint()..color = Colors.black);
    // Shine
    canvas.drawCircle(
        const Offset(24.5, 14.5), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(30, 23), 1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BubPreviewPainter old) =>
      old.character != character;
}
