import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';

enum _FoodType { pudding, watermelon, cake, cherry, starCandy }

class Coin extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  double t = 0;
  late final double startY;
  bool collected = false;
  late final _FoodType _food;

  Coin({required Vector2 position})
      : super(position: position, size: Vector2(22, 22), anchor: Anchor.topLeft) {
    startY = position.y;
    final hash = (position.x * 7 + position.y * 13).toInt().abs() % 5;
    _food = _FoodType.values[hash];
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
        player.position.x, player.position.y, player.size.x, player.size.y);
      if (rect.overlaps(pr)) {
        collected = true;
        game.onCoinCollected(this);
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    switch (_food) {
      case _FoodType.pudding:    _drawPudding(canvas);    break;
      case _FoodType.watermelon: _drawWatermelon(canvas); break;
      case _FoodType.cake:       _drawCake(canvas);       break;
      case _FoodType.cherry:     _drawCherry(canvas);     break;
      case _FoodType.starCandy:  _drawStarCandy(canvas);  break;
    }
  }

  // ── Pudding: brown dome with cream swirl ─────────────────────────────────

  void _drawPudding(Canvas canvas) {
    // Brown base
    canvas.drawOval(
      Rect.fromLTWH(2, 8, 18, 13),
      Paint()..color = const Color(0xFF795548),
    );
    // Dome
    canvas.drawArc(
      Rect.fromLTWH(1, 3, 20, 16),
      math.pi, math.pi, false,
      Paint()..color = const Color(0xFF8D6E63),
    );
    // Cream top
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(11, 5), width: 14, height: 7),
      Paint()..color = const Color(0xFFFFF8E1),
    );
    // Swirl dot
    canvas.drawCircle(const Offset(11, 5), 2.5, Paint()..color = const Color(0xFFFFCC80));
    // Outline
    canvas.drawOval(
      Rect.fromLTWH(2, 8, 18, 13),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // ── Watermelon: red/green half-slice with seeds ──────────────────────────

  void _drawWatermelon(Canvas canvas) {
    // Green rind
    canvas.drawArc(
      Rect.fromLTWH(1, 2, 20, 20),
      math.pi, math.pi, true,
      Paint()..color = const Color(0xFF4CAF50),
    );
    // White pith
    canvas.drawArc(
      Rect.fromLTWH(3, 4, 16, 16),
      math.pi, math.pi, true,
      Paint()..color = Colors.white,
    );
    // Red flesh
    canvas.drawArc(
      Rect.fromLTWH(4, 5, 14, 14),
      math.pi, math.pi, true,
      Paint()..color = const Color(0xFFEF5350),
    );
    // Seeds
    for (final s in [const Offset(7, 10), const Offset(11, 8), const Offset(15, 10)]) {
      canvas.drawOval(Rect.fromCenter(center: s, width: 2, height: 3),
          Paint()..color = Colors.black);
    }
    // Rind line
    canvas.drawArc(
      Rect.fromLTWH(1, 2, 20, 20),
      math.pi, math.pi, false,
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // ── Cake: two-layer slice ────────────────────────────────────────────────

  void _drawCake(Canvas canvas) {
    // Bottom layer (chocolate)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 12, 16, 9), const Radius.circular(2)),
      Paint()..color = const Color(0xFF6D4C41),
    );
    // Top layer (pink)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 7, 14, 7), const Radius.circular(2)),
      Paint()..color = const Color(0xFFF48FB1),
    );
    // White frosting on top
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 5, 16, 4), const Radius.circular(3)),
      Paint()..color = Colors.white,
    );
    // Frosting drip drops
    for (final dx in [5.0, 9.0, 13.0]) {
      canvas.drawCircle(Offset(dx + 2, 9), 1.5, Paint()..color = Colors.white);
    }
    // Cherry on top
    canvas.drawCircle(const Offset(11, 4), 3, Paint()..color = const Color(0xFFE53935));
  }

  // ── Cherry: two red circles with stem ───────────────────────────────────

  void _drawCherry(Canvas canvas) {
    // Stems
    final stemPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(8, 7),  const Offset(11, 2), stemPaint);
    canvas.drawLine(const Offset(14, 7), const Offset(11, 2), stemPaint);
    // Left cherry
    canvas.drawCircle(const Offset(8, 13), 5.5, Paint()..color = const Color(0xFFD32F2F));
    canvas.drawCircle(const Offset(8, 13), 5.5,
        Paint()..color = const Color(0xFF7F0000)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(const Offset(6, 11), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
    // Right cherry
    canvas.drawCircle(const Offset(14, 13), 5.5, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(const Offset(14, 13), 5.5,
        Paint()..color = const Color(0xFF7F0000)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(const Offset(12, 11), 1.5, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  // ── Star candy: 5-pointed star ───────────────────────────────────────────

  void _drawStarCandy(Canvas canvas) {
    final path = _starPath(const Offset(11, 11), 10, 4.5, 5);
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD600));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF6F00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Center shine
    canvas.drawCircle(const Offset(11, 11), 3, Paint()..color = Colors.white.withValues(alpha: 0.5));
  }

  static Path _starPath(Offset center, double outerR, double innerR, int points) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    return path..close();
  }
}
