import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/world/level_data.dart';
import '../services/save_service.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = LevelData.all();
    final unlocked = SaveService.instance.data.unlockedLevels;
    final stars = SaveService.instance.data.levelStars;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Select Level',
          style: GoogleFonts.fredoka(
            color: Colors.white,
            fontSize: 24,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final world in [1, 2, 3]) ...[
            _WorldHeader(world: world),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: levels.where((l) => l.world == world).map((l) {
                final isUnlocked = l.level <= unlocked;
                final s = stars[l.level] ?? 0;
                return _LevelTile(
                  spec: l,
                  unlocked: isUnlocked,
                  stars: s,
                  onTap: isUnlocked ? () => context.go('/game/${l.level}') : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

// ── World header banner ───────────────────────────────────────────────────────

class _WorldHeader extends StatelessWidget {
  final int world;
  const _WorldHeader({required this.world});

  @override
  Widget build(BuildContext context) {
    final cfg = _worldConfig(world);
    return SizedBox(
      height: 72,
      child: Stack(
        children: [
          // Banner background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: const Size(double.infinity, 72),
              painter: _WorldBannerPainter(world, cfg),
            ),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(cfg.icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORLD $world',
                        style: GoogleFonts.fredoka(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        cfg.name,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 22,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '5 LEVELS',
                    style: GoogleFonts.fredoka(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _WorldCfg _worldConfig(int world) {
    switch (world) {
      case 1:
        return _WorldCfg(
          name: 'Bamboo Jungle',
          icon: '🌿',
          gradientColors: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          borderColor: const Color(0xFF76FF03),
          decorType: _DecorType.bamboo,
        );
      case 2:
        return _WorldCfg(
          name: 'Ghost Forest',
          icon: '🌲',
          gradientColors: const [Color(0xFF0D1B2A), Color(0xFF1A3A2A)],
          borderColor: const Color(0xFF69F0AE),
          decorType: _DecorType.vine,
        );
      default:
        return _WorldCfg(
          name: 'Fire Volcano',
          icon: '🌋',
          gradientColors: const [Color(0xFF4A0000), Color(0xFF7F0000)],
          borderColor: const Color(0xFFFF6F00),
          decorType: _DecorType.flame,
        );
    }
  }
}

enum _DecorType { bamboo, vine, flame }

class _WorldCfg {
  final String name;
  final String icon;
  final List<Color> gradientColors;
  final Color borderColor;
  final _DecorType decorType;
  const _WorldCfg({
    required this.name,
    required this.icon,
    required this.gradientColors,
    required this.borderColor,
    required this.decorType,
  });
}

class _WorldBannerPainter extends CustomPainter {
  final int world;
  final _WorldCfg cfg;
  _WorldBannerPainter(this.world, this.cfg);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(16));

    // Background gradient
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(colors: cfg.gradientColors)
            .createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Decorative elements
    switch (cfg.decorType) {
      case _DecorType.bamboo:
        _drawBambooDecor(canvas, w, h);
        break;
      case _DecorType.vine:
        _drawVineDecor(canvas, w, h);
        break;
      case _DecorType.flame:
        _drawFlameDecor(canvas, w, h);
        break;
    }

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = cfg.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawBambooDecor(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFF558B2F).withValues(alpha: 0.4);
    for (final x in [w * 0.72, w * 0.78, w * 0.85, w * 0.91]) {
      canvas.drawRect(Rect.fromLTWH(x - 5, 0, 10, h), paint);
      for (double y = 8; y < h; y += 16) {
        canvas.drawRect(Rect.fromLTWH(x - 7, y, 14, 2.5),
            Paint()..color = const Color(0xFF33691E).withValues(alpha: 0.35));
      }
    }
  }

  void _drawVineDecor(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final x = w * (0.65 + i * 0.07);
      final path = Path()..moveTo(x, 0);
      for (double y = 8; y <= h; y += 8) {
        path.lineTo(x + math.sin(y * 0.4 + i) * 5, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawFlameDecor(Canvas canvas, double w, double h) {
    final colors = [
      const Color(0xFFFF6F00).withValues(alpha: 0.35),
      const Color(0xFFFFD600).withValues(alpha: 0.2),
    ];
    for (int i = 0; i < 6; i++) {
      final x = w * (0.62 + i * 0.06);
      final flameH = h * (0.5 + (i % 2) * 0.25);
      final path = Path()
        ..moveTo(x - 6, h)
        ..quadraticBezierTo(x - 10, h - flameH * 0.5, x, h - flameH)
        ..quadraticBezierTo(x + 10, h - flameH * 0.5, x + 6, h)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i % 2]);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldBannerPainter old) => false;
}

// ── Level tile ────────────────────────────────────────────────────────────────

class _LevelTile extends StatelessWidget {
  final LevelSpec spec;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.spec,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  Color get _gemColor {
    switch (spec.world) {
      case 1: return const Color(0xFF43A047);
      case 2: return const Color(0xFF1565C0);
      default: return const Color(0xFFBF360C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: spec.isBoss
                ? const Color(0xFFFFD600)
                : unlocked
                    ? _gemColor.withValues(alpha: 0.6)
                    : Colors.white12,
            width: spec.isBoss ? 2.5 : 1.5,
          ),
          boxShadow: unlocked
              ? [BoxShadow(
                  color: _gemColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                )]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              CustomPaint(
                size: const Size(24, 28),
                painter: _LockPainter(),
              )
            else if (spec.isBoss)
              Column(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 20)),
                  Text(
                    'BOSS',
                    style: GoogleFonts.fredoka(
                      color: const Color(0xFFFFD600),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              )
            else
              // Gem bubble with level number
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gemColor.withValues(alpha: 0.9),
                      _gemColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gemColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${spec.level}',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                  ),
                ),
              ),
            const SizedBox(height: 5),
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                Icons.star_rounded,
                color: i < stars
                    ? const Color(0xFFFFD600)
                    : Colors.white12,
                size: 12,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Shackle arc
    final arc = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, size.height * 0.38), width: 14, height: 12),
      math.pi, math.pi, false, arc,
    );
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 8, size.height * 0.45, 16, 13),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white38,
    );
    // Keyhole
    canvas.drawCircle(
      Offset(cx, size.height * 0.55), 2.5,
      Paint()..color = Colors.black38,
    );
  }

  @override
  bool shouldRepaint(covariant _LockPainter old) => false;
}
