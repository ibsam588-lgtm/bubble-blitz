import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';

class GameHud extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  GameHud() : super(priority: 100);

  @override
  void render(Canvas canvas) {
    final w = game.worldSize.x;
    // Top bar background
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 44), bg);

    final mgr = game.manager;

    // Score (left)
    final scoreTp = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    scoreTp.render(canvas, 'SCORE  ${mgr.score}', Vector2(12, 14));

    // Lives (center) using hearts
    final heart = TextPaint(
      style: const TextStyle(fontSize: 18, color: Colors.white),
    );
    final livesStr = '❤' * mgr.lives.clamp(0, 9);
    heart.render(canvas, livesStr, Vector2(w / 2 - 30, 12));

    // Coins (right)
    final coinTp = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFFFFEB3B),
        fontWeight: FontWeight.bold,
      ),
    );
    coinTp.render(canvas, '🪙 ${mgr.coinsCollected}', Vector2(w - 92, 14));

    // Power-up indicators
    if (mgr.bigBubbleActive || mgr.multiBubbleShots > 0) {
      final y = 50.0;
      final tp = TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      final parts = <String>[];
      if (mgr.bigBubbleActive) {
        parts.add('BIG ${mgr.bigBubbleTimer.toStringAsFixed(1)}s');
      }
      if (mgr.multiBubbleShots > 0) {
        parts.add('×3 ${mgr.multiBubbleShots}');
      }
      tp.render(canvas, parts.join('   '), Vector2(12, y));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  }
}
