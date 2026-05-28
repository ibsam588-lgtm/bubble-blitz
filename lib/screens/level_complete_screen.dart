import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/managers/game_manager.dart';
import '../utils/constants.dart';

class LevelCompleteScreen extends StatelessWidget {
  final GameManager manager;
  final Future<void> Function() onNext;
  final Future<void> Function() onRetry;
  final VoidCallback onExit;

  const LevelCompleteScreen({
    super.key,
    required this.manager,
    required this.onNext,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final stars = manager.starsEarned();
    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Stack(
        children: [
          // Burst ray background
          Positioned.fill(
            child: CustomPaint(painter: _BurstPainter()).animate().fadeIn(duration: 400.ms),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "LEVEL CLEAR!" title
                Text(
                  'LEVEL CLEAR!',
                  style: GoogleFonts.fredoka(
                    fontSize: 44,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFFFEB3B), Color(0xFFFFD600), Color(0xFFFF9800)],
                      ).createShader(const Rect.fromLTWH(0, 0, 260, 50)),
                    shadows: const [
                      Shadow(color: Colors.black, offset: Offset(-3, -3), blurRadius: 0),
                      Shadow(color: Colors.black, offset: Offset( 3, -3), blurRadius: 0),
                      Shadow(color: Colors.black, offset: Offset(-3,  3), blurRadius: 0),
                      Shadow(color: Colors.black, offset: Offset( 3,  3), blurRadius: 0),
                      Shadow(color: Colors.black, offset: Offset( 0,  5), blurRadius: 6),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 20),
                // Star rating reveal
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 1; i <= 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: _StarWidget(filled: i <= stars, delay: 150 * i),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                // Score tally panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _scoreLine('SCORE', '${manager.score}', Colors.white),
                      const SizedBox(height: 6),
                      _scoreLine('FOOD', '${manager.coinsCollected}', AppConstants.accentYellow),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),
                const SizedBox(height: 28),
                // Action buttons
                _gradientButton(
                  icon: Icons.arrow_forward_rounded,
                  label: 'NEXT LEVEL',
                  colors: const [Color(0xFF26C6DA), Color(0xFF00838F)],
                  onTap: () => onNext(),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
                const SizedBox(height: 10),
                _gradientButton(
                  icon: Icons.refresh_rounded,
                  label: 'RETRY',
                  colors: const [Color(0xFFFF9800), Color(0xFFE65100)],
                  onTap: () => onRetry(),
                ).animate().fadeIn(delay: 880.ms).slideY(begin: 0.3),
                const SizedBox(height: 10),
                _gradientButton(
                  icon: Icons.home_rounded,
                  label: 'MAIN MENU',
                  colors: [Colors.white24, Colors.white12],
                  onTap: () async => onExit(),
                ).animate().fadeIn(delay: 960.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreLine(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              color: Colors.white60,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.fredoka(
            color: valueColor,
            fontSize: 22,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated star widget ──────────────────────────────────────────────────────

class _StarWidget extends StatelessWidget {
  final bool filled;
  final int delay;
  const _StarWidget({required this.filled, required this.delay});

  @override
  Widget build(BuildContext context) {
    return (filled
            ? const Icon(Icons.star_rounded, color: Color(0xFFFFD600), size: 60)
            : const Icon(Icons.star_rounded, color: Colors.white12, size: 60))
        .animate(delay: delay.ms)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}

// ── Burst ray painter ─────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const numRays = 16;
    final maxLen = math.sqrt(cx * cx + cy * cy) * 1.3;

    for (int i = 0; i < numRays; i++) {
      final angle = (i / numRays) * 2 * math.pi - math.pi / 2;
      final nextAngle = ((i + 0.4) / numRays) * 2 * math.pi - math.pi / 2;
      final isLight = i.isEven;

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(angle) * maxLen,
          cy + math.sin(angle) * maxLen,
        )
        ..lineTo(
          cx + math.cos(nextAngle) * maxLen,
          cy + math.sin(nextAngle) * maxLen,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = (isLight
              ? const Color(0xFFFFEB3B)
              : const Color(0xFFFF9800))
              .withValues(alpha: 0.10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => false;
}
