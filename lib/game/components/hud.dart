import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';

class GameHud extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  GameHud() : super(priority: 100);

  static const double _barH = 48.0;

  @override
  void render(Canvas canvas) {
    final w = game.worldSize.x;
    final mgr = game.manager;

    // ── Panel background ──────────────────────────────────────────────────
    final bgRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, _barH),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(bgRRect, Paint()..color = Colors.black.withValues(alpha: 0.62));

    // Orange accent border (bottom edge + sides)
    canvas.drawRRect(
      bgRRect,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Bamboo border decoration (top) ────────────────────────────────────
    _drawBambooBorder(canvas, w);

    // ── Score (left) ──────────────────────────────────────────────────────
    _drawLabel(canvas, 'SCORE', 10, 6, const Color(0xFFFF9800));
    _drawValue(canvas, '${mgr.score}', 10, 22);

    // ── Lives (center) as tiny Bub heads ─────────────────────────────────
    _drawLives(canvas, w, mgr.lives);

    // ── Food / coins (right) ─────────────────────────────────────────────
    _drawFoodBasket(canvas, w - 88, 8);
    _drawValue(canvas, '${mgr.coinsCollected}', w - 60, 24, size: 16);

    // ── Power-up badges (below bar) ───────────────────────────────────────
    if (mgr.bigBubbleActive || mgr.multiBubbleShots > 0) {
      double bx = 10;
      if (mgr.bigBubbleActive) {
        bx = _drawBadge(canvas, 'BIG  ${mgr.bigBubbleTimer.toStringAsFixed(1)}s',
            bx, _barH + 4, const Color(0xFFFF9800));
        bx += 6;
      }
      if (mgr.multiBubbleShots > 0) {
        _drawBadge(canvas, '×3  ${mgr.multiBubbleShots}',
            bx, _barH + 4, const Color(0xFF1565C0));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _drawBambooBorder(Canvas canvas, double w) {
    final paint = Paint()..color = const Color(0xFF558B2F);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 4), paint);
    // Node rings
    final nodePaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (double nx = 16; nx < w; nx += 16) {
      canvas.drawLine(Offset(nx, 0), Offset(nx, 4), nodePaint);
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPaint(
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
    tp.render(canvas, text, Vector2(x, y));
  }

  void _drawValue(Canvas canvas, String text, double x, double y,
      {double size = 17}) {
    final tp = TextPaint(
      style: TextStyle(
        fontSize: size,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
      ),
    );
    tp.render(canvas, text, Vector2(x, y));
  }

  void _drawLives(Canvas canvas, double w, int lives) {
    final count = lives.clamp(0, 5);
    final totalW = count * 22.0;
    double lx = w / 2 - totalW / 2;
    for (int i = 0; i < count; i++) {
      _drawBubHead(canvas, lx + 11, 24);
      lx += 22;
    }
  }

  // Tiny Bub dragon head icon
  void _drawBubHead(Canvas canvas, double cx, double cy) {
    // Body
    canvas.drawCircle(Offset(cx, cy), 9, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(
        Offset(cx, cy), 9,
        Paint()
          ..color = const Color(0xFF1B5E20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Eye
    canvas.drawCircle(Offset(cx + 3, cy - 2), 3.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 4, cy - 2), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx + 2.5, cy - 3.5), 0.8, Paint()..color = Colors.white);
    // Horn nub
    canvas.drawPath(
      Path()
        ..moveTo(cx + 2, cy - 9)
        ..lineTo(cx + 5, cy - 14)
        ..lineTo(cx + 8, cy - 9)
        ..close(),
      Paint()..color = const Color(0xFF1B5E20),
    );
  }

  // Small basket/food icon
  void _drawFoodBasket(Canvas canvas, double x, double y) {
    // Basket body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 6, 22, 14), const Radius.circular(3)),
      Paint()..color = const Color(0xFF8D6E63),
    );
    // Basket weave lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(x + 1, y + 6 + i * 4),
        Offset(x + 21, y + 6 + i * 4),
        Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 1,
      );
    }
    // Handle arc
    canvas.drawArc(
      Rect.fromLTWH(x + 3, y - 2, 16, 12),
      math.pi, math.pi,
      false,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Food dot in basket (red cherry)
    canvas.drawCircle(Offset(x + 7, y + 9), 3, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(Offset(x + 14, y + 10), 3, Paint()..color = const Color(0xFFFFD600));
    // Label
    final tp = TextPaint(
      style: const TextStyle(fontSize: 10, color: Color(0xFFFFEB3B), fontWeight: FontWeight.bold),
    );
    tp.render(canvas, 'FOOD', Vector2(x - 2, y + 22));
  }

  double _drawBadge(Canvas canvas, String text, double x, double y, Color color) {
    const fontSize = 12.0;
    const padH = 8.0;
    const badgeH = 20.0;
    final textW = text.length * 7.5; // approximate
    final badgeW = textW + padH * 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, badgeW, badgeH), const Radius.circular(10)),
      Paint()..color = color.withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, badgeW, badgeH), const Radius.circular(10)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final tp = TextPaint(
      style: const TextStyle(
        fontSize: fontSize,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.render(canvas, text, Vector2(x + padH, y + 4));
    return x + badgeW;
  }

  @override
  void update(double dt) => super.update(dt);
}
