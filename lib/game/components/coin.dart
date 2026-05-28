import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';

class Coin extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  double t = 0;
  late final double startY;
  bool collected = false;

  Coin({required Vector2 position})
      : super(
            position: position, size: Vector2(20, 20), anchor: Anchor.topLeft) {
    startY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    position.y = startY + math.sin(t * 3) * 3;

    if (!collected) {
      final rect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
      for (final player in game.activePlayers) {
        final pr = Rect.fromLTWH(
          player.position.x,
          player.position.y,
          player.size.x,
          player.size.y,
        );
        if (rect.overlaps(pr)) {
          collected = true;
          game.onCoinCollected(this);
          removeFromParent();
          return;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      c,
      size.x / 2,
      Paint()..color = AppConstants.accentYellow,
    );
    canvas.drawCircle(
      c,
      size.x / 2 - 2,
      Paint()..color = AppConstants.foamWhite.withValues(alpha: 0.36),
    );
    canvas.drawCircle(
      Offset(c.dx - 3, c.dy - 3),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    final tp = TextPaint(
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppConstants.uiDark,
      ),
    );
    tp.render(canvas, 'B', Vector2(size.x / 2 - 4, size.y / 2 - 7));
  }
}
