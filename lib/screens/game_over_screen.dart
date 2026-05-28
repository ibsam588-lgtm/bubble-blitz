import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/managers/game_manager.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class GameOverScreen extends StatelessWidget {
  final GameManager manager;
  final Future<void> Function() onContinueWithCoins;
  final Future<void> Function() onContinueWithAd;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameOverScreen({
    super.key,
    required this.manager,
    required this.onContinueWithCoins,
    required this.onContinueWithAd,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final coins = SaveService.instance.data.coins;
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cracked bubble graphic
            CustomPaint(
              size: const Size(130, 130),
              painter: _CrackedBubblePainter(),
            ).animate().scale(
              begin: const Offset(0.6, 0.6),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 4),
            // "GAME OVER" with red drip effect
            Text(
              'GAME OVER',
              style: GoogleFonts.fredoka(
                color: const Color(0xFFEF5350),
                fontSize: 52,
                shadows: const [
                  // Black outline effect
                  Shadow(color: Colors.black, offset: Offset(-3, -3), blurRadius: 0),
                  Shadow(color: Colors.black, offset: Offset( 3, -3), blurRadius: 0),
                  Shadow(color: Colors.black, offset: Offset(-3,  3), blurRadius: 0),
                  Shadow(color: Colors.black, offset: Offset( 3,  3), blurRadius: 0),
                  // Drip shadows (downward offsets)
                  Shadow(color: Color(0xFF7F0000), offset: Offset(0, 4), blurRadius: 0),
                  Shadow(color: Color(0xFF7F0000), offset: Offset(0, 8), blurRadius: 0),
                  Shadow(color: Color(0xFF7F0000), offset: Offset(0, 12), blurRadius: 4),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
            const SizedBox(height: 6),
            Text(
              'Score: ${manager.score}',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 26,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
            const SizedBox(height: 28),
            _btn(
              icon: Icons.play_circle_rounded,
              colors: const [Color(0xFFFF9800), Color(0xFFE65100)],
              label: 'Watch Ad to Continue',
              onTap: onContinueWithAd,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3),
            const SizedBox(height: 10),
            _btn(
              icon: Icons.monetization_on_rounded,
              colors: const [Color(0xFFFFD600), Color(0xFFFF8F00)],
              label: 'Use ${AppConstants.continueCost} 🪙 ($coins)',
              onTap: onContinueWithCoins,
              textColor: Colors.black87,
            ).animate().fadeIn(delay: 380.ms).slideX(begin: 0.3),
            const SizedBox(height: 10),
            _btn(
              icon: Icons.refresh_rounded,
              colors: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
              label: 'Restart',
              onTap: () async => onRestart(),
            ).animate().fadeIn(delay: 460.ms).slideX(begin: -0.3),
            const SizedBox(height: 10),
            _btn(
              icon: Icons.home_rounded,
              colors: [Colors.white24, Colors.white12],
              label: 'Main Menu',
              onTap: () async => onExit(),
            ).animate().fadeIn(delay: 540.ms).slideX(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required List<Color> colors,
    required String label,
    required Future<void> Function() onTap,
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 290,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.fredoka(
                    fontSize: 16, color: textColor,
                    shadows: textColor == Colors.white
                        ? const [Shadow(color: Colors.black38, blurRadius: 3)]
                        : null)),
          ],
        ),
      ),
    );
  }
}

// ── Cracked bubble painter ────────────────────────────────────────────────────

class _CrackedBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy), r + 8,
      Paint()..color = const Color(0xFFEF5350).withValues(alpha: 0.15),
    );

    // Bubble circle fill
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = const Color(0xFF26C6DA).withValues(alpha: 0.18),
    );

    // Bubble outline
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = const Color(0xFF26C6DA).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Crack lines emanating from center
    final crackPaint = Paint()
      ..color = const Color(0xFFEF5350)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rand = math.Random(7);
    const numCracks = 8;
    for (int i = 0; i < numCracks; i++) {
      final angle = (i / numCracks) * 2 * math.pi + rand.nextDouble() * 0.4;
      final len = r * (0.55 + rand.nextDouble() * 0.55);
      final midLen = len * 0.5;
      final midAngle = angle + (rand.nextDouble() - 0.5) * 0.5;

      final path = Path()
        ..moveTo(cx, cy)
        ..lineTo(
          cx + math.cos(midAngle) * midLen,
          cy + math.sin(midAngle) * midLen,
        )
        ..lineTo(
          cx + math.cos(angle) * len,
          cy + math.sin(angle) * len,
        );
      canvas.drawPath(path, crackPaint);
    }

    // Small debris dots around bubble
    for (int i = 0; i < 12; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final dist = r + 6 + rand.nextDouble() * 16;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
        1.5 + rand.nextDouble() * 2,
        Paint()..color = const Color(0xFF26C6DA).withValues(alpha: 0.5),
      );
    }

    // Highlight arc on bubble
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.2, cy - r * 0.2), width: r * 0.7, height: r * 0.4),
      math.pi * 1.2, math.pi * 0.6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _CrackedBubblePainter old) => false;
}
