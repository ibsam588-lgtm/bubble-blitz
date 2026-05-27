import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world/level_data.dart';

class GamePlatform extends PositionComponent {
  final PlatformSpec spec;
  final Color color;
  double _t = 0;
  late final double _startX;

  GamePlatform({required this.spec, required this.color})
      : super(
          position: Vector2(spec.x, spec.y),
          size: Vector2(spec.width, spec.height),
        ) {
    _startX = spec.x;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (spec.moving) {
      _t += dt;
      position.x = _startX + (spec.moveRange * 0.5) * (1 + math.sin(_t * 1.6));
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..color = color;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, paint);

    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.25);
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.x - 4, 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(highlightRect, highlight);
  }

  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
