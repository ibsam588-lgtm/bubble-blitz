import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';

/// Classic BB2-style HUD: SCORE left, HI-SCORE center, 1P×lives right.
class GameHud extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  GameHud() : super(priority: 100);

  static const double _barH = 52.0;
  static const _scoreLabel = TextStyle(
    fontSize: 10,
    color: Color(0xFFFFEB3B),
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
  );
  static const _scoreValue = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
  );
  static const _livesStyle = TextStyle(
    fontSize: 15,
    color: Color(0xFF69F0AE),
    fontWeight: FontWeight.bold,
    shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
  );
  static const _levelStyle = TextStyle(
    fontSize: 11,
    color: Color(0xFF80DEEA),
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
  );

  @override
  void render(Canvas canvas) {
    final w = game.worldSize.x;
    final mgr = game.manager;

    // ── Panel background — semi-transparent black with pixel border ───────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, _barH),
      Paint()..color = const Color(0xE0050A12),
    );

    // Top pixel-border line (bright)
    canvas.drawLine(
      const Offset(0, 0),
      Offset(w, 0),
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..strokeWidth = 2.0,
    );
    // Bottom border line (dim)
    canvas.drawLine(
      Offset(0, _barH),
      Offset(w, _barH),
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );

    // ── SCORE (left) ───────────────────────────────────────────────────────
    _tp(_scoreLabel).render(canvas, 'SCORE', Vector2(10, 7));
    _tp(_scoreValue).render(canvas, _fmt(mgr.score, 7), Vector2(10, 22));

    // ── HI-SCORE (center) ─────────────────────────────────────────────────
    final hiStr = _fmt(game.manager.hiScore, 7);
    final hiLabelW = 50.0;
    final hiX = w / 2 - hiLabelW / 2;
    _tp(_scoreLabel).render(canvas, 'HI-SCORE', Vector2(hiX - 4, 7));
    _tp(_scoreValue).render(canvas, hiStr, Vector2(hiX, 22));

    // ── Lives — 1P×N format (right side) ─────────────────────────────────
    final livesStr = '1P×${mgr.lives.clamp(0, 9)}';
    final livesX = w - 72.0;
    // Small Bub head icon
    _drawMiniHead(canvas, livesX, 26, game.manager.playerCharColor);
    _tp(_livesStyle).render(canvas, livesStr, Vector2(livesX + 16, 18));

    // ── Level indicator (far right) ───────────────────────────────────────
    _tp(_levelStyle)
        .render(canvas, 'LV ${mgr.currentLevel}', Vector2(w - 44, 7));

    // ── Coins ─────────────────────────────────────────────────────────────
    _drawCoinIcon(canvas, 10, _barH + 6);
    _tp(const TextStyle(
      fontSize: 13, color: Color(0xFFFFD740), fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
    )).render(canvas, '${mgr.coinsCollected}', Vector2(26, _barH + 5));

    // ── Power-up badges ───────────────────────────────────────────────────
    if (mgr.bigBubbleActive || mgr.multiBubbleShots > 0) {
      double bx = 70;
      if (mgr.bigBubbleActive) {
        bx = _drawBadge(canvas, 'BIG ${mgr.bigBubbleTimer.toStringAsFixed(1)}s',
            bx, _barH + 4, const Color(0xFFFF9800)) + 6;
      }
      if (mgr.multiBubbleShots > 0) {
        _drawBadge(canvas, '×3  ${mgr.multiBubbleShots}',
            bx, _barH + 4, const Color(0xFF1565C0));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  TextPaint _tp(TextStyle style) => TextPaint(style: style);

  /// Format score with leading zeros.
  String _fmt(int n, int digits) => n.toString().padLeft(digits, '0');

  /// Tiny BB2-style Bub head.
  void _drawMiniHead(Canvas canvas, double x, double y, Color col) {
    canvas.drawCircle(Offset(x, y), 7, Paint()..color = col);
    canvas.drawCircle(Offset(x, y), 7,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // Eye
    canvas.drawCircle(Offset(x + 2.5, y - 1), 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x + 3, y - 0.5), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(x + 1.5, y - 2.5), 0.8, Paint()..color = Colors.white);
    // Horn
    canvas.drawPath(
      Path()
        ..moveTo(x + 1, y - 6)
        ..quadraticBezierTo(x + 6, y - 12, x + 7, y - 7)
        ..lineTo(x + 4, y - 6)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  void _drawCoinIcon(Canvas canvas, double x, double y) {
    canvas.drawCircle(Offset(x, y + 6), 7,
        Paint()..color = const Color(0xFFFFD740));
    canvas.drawCircle(Offset(x, y + 6), 7,
        Paint()
          ..color = const Color(0xFFFF8F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    _tp(const TextStyle(
      fontSize: 9,
      color: Color(0xFFFF6F00),
      fontWeight: FontWeight.bold,
    )).render(canvas, '¢', Vector2(x - 3.5, y + 1));
  }

  double _drawBadge(
      Canvas canvas, String text, double x, double y, Color color) {
    const fontSize = 11.0;
    const padH = 7.0;
    const badgeH = 19.0;
    final textW = text.length * 7.0;
    final badgeW = textW + padH * 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, badgeW, badgeH), const Radius.circular(9)),
      Paint()..color = color.withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, badgeW, badgeH), const Radius.circular(9)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    _tp(TextStyle(
      fontSize: fontSize,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
    )).render(canvas, text, Vector2(x + padH, y + 4));
    return x + badgeW;
  }

  @override
  void update(double dt) => super.update(dt);
}
