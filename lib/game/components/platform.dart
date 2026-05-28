import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
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
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD7B166),
          AppConstants.bark,
          AppConstants.barkDark,
        ],
        stops: [0, 0.55, 1],
      ).createShader(rect);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(rrect, paint);

    canvas.drawOval(
      Rect.fromLTWH(-4, 1, 15, size.y - 2),
      Paint()..color = const Color(0xFF7B4A27),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x - 11, 1, 15, size.y - 2),
      Paint()..color = const Color(0xFF7B4A27),
    );
    canvas.drawOval(
      Rect.fromLTWH(1, 5, 7, size.y - 10),
      Paint()..color = const Color(0xFFE6C57A),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x - 8, 5, 7, size.y - 10),
      Paint()..color = const Color(0xFFE6C57A),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = AppConstants.barkDark.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final highlight = Paint()..color = AppConstants.moss;
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, -1, size.x - 6, 6),
      const Radius.circular(4),
    );
    canvas.drawRRect(highlightRect, highlight);

    final barkLine = Paint()
      ..color = const Color(0xFF6B4427).withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (double y = 6; y < size.y - 2; y += 5) {
      canvas.drawLine(Offset(10, y), Offset(size.x - 10, y + 1.5), barkLine);
    }

    final vinePaint = Paint()
      ..color = AppConstants.vine
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (double x = 18; x < size.x; x += 36) {
      canvas.drawLine(Offset(x, -2), Offset(x + 13, size.y + 2), vinePaint);
      canvas.drawLine(Offset(x + 5, size.y + 1), Offset(x + 19, -1), vinePaint);
    }
  }

  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
