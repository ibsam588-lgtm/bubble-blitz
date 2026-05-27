import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';

class Powerup extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  final String kind; // 'multi' or 'big'
  double t = 0;
  late final double startY;
  bool collected = false;

  Powerup({required Vector2 position, required this.kind})
      : super(position: position, size: Vector2(26, 26), anchor: Anchor.topLeft) {
    startY = position.y;
  }

  Color get color => kind == 'multi'
      ? Colors.pinkAccent
      : Colors.cyanAccent.shade400;

  String get glyph => kind == 'multi' ? '×3' : 'B';

  @override
  void update(double dt) {
    super.update(dt);
    t += dt;
    position.y = startY + math.sin(t * 3) * 4;

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
        game.onPowerupCollected(this);
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, size.x / 2, Paint()..color = color);
    canvas.drawCircle(
      c,
      size.x / 2 - 2,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
    final tp = TextPaint(
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    tp.render(canvas, glyph, Vector2(size.x / 2 - 8, size.y / 2 - 8));
  }
}
