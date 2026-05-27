import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';
import 'player.dart';

class Coin extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  double t = 0;
  late final double startY;
  bool collected = false;

  Coin({required Vector2 position})
      : super(position: position, size: Vector2(20, 20), anchor: Anchor.topLeft) {
    startY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    position.y = startY + math.sin(t * 3) * 3;

    final player = game.player;
    if (player != null && !collected) {
      final rect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
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
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, size.x / 2, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(
      c,
      size.x / 2 - 2,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    final tp = TextPaint(
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFB8860B),
      ),
    );
    tp.render(canvas, '\$', Vector2(size.x / 2 - 3, size.y / 2 - 7));
  }
}
