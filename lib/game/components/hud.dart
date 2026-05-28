import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';

class GameHud extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  GameHud() : super(priority: 100);

  @override
  void render(Canvas canvas) {
    final w = game.viewSize.x;
    // Top bar background
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, w - 16, 48),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      barRect,
      Paint()..color = AppConstants.uiDark.withValues(alpha: 0.86),
    );
    canvas.drawRRect(
      barRect,
      Paint()
        ..color = AppConstants.accentYellow.withValues(alpha: 0.74)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final mgr = game.manager;

    // Score (left)
    final labelTp = TextPaint(
      style: const TextStyle(
        fontSize: 11,
        color: AppConstants.accentYellow,
        fontWeight: FontWeight.bold,
      ),
    );
    final valueTp = TextPaint(
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    labelTp.render(canvas, '1P-SCORE', Vector2(22, 16));
    valueTp.render(canvas, '${mgr.score}', Vector2(23, 32));

    // Lives (center)
    labelTp.render(canvas, 'HI-SCORE', Vector2(w / 2 - 38, 16));
    valueTp.render(canvas, '${mgr.score}', Vector2(w / 2 - 24, 32));

    final lifeTp = TextPaint(
      style: const TextStyle(
        fontSize: 15,
        color: AppConstants.heroGreen,
        fontWeight: FontWeight.bold,
      ),
    );
    lifeTp.render(
      canvas,
      'LIFE ${mgr.lives.clamp(0, 9)}',
      Vector2(w - 174, 18),
    );

    // Coins (right)
    final coinTp = TextPaint(
      style: const TextStyle(
        fontSize: 15,
        color: AppConstants.accentYellow,
        fontWeight: FontWeight.bold,
      ),
    );
    coinTp.render(
      canvas,
      'BITS ${mgr.coinsCollected}',
      Vector2(w - 96, 18),
    );

    // Power-up indicators
    if (mgr.bigBubbleActive || mgr.multiBubbleShots > 0) {
      const y = 58.0;
      final tp = TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: AppConstants.foamWhite,
          fontWeight: FontWeight.bold,
        ),
      );
      final parts = <String>[];
      if (mgr.bigBubbleActive) {
        parts.add('BIG ${mgr.bigBubbleTimer.toStringAsFixed(1)}s');
      }
      if (mgr.multiBubbleShots > 0) {
        parts.add('x3 ${mgr.multiBubbleShots}');
      }
      tp.render(canvas, parts.join('   '), Vector2(12, y));
    }
  }
}
