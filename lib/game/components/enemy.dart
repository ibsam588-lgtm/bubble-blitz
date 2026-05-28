import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';
import 'platform.dart';
import 'player.dart';

abstract class Enemy extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  int health;
  bool isTrapped = false;
  String emoji;
  Color color;
  int scoreValue;

  Enemy({
    required Vector2 position,
    required Vector2 size,
    required this.health,
    required this.emoji,
    required this.color,
    required this.scoreValue,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  void onTrapped() {
    isTrapped = true;
  }

  void onEscape() {
    isTrapped = false;
  }

  bool checkPlayerCollision(Player player) {
    if (isTrapped) return false;
    final myRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    final playerRect = Rect.fromLTWH(
      player.position.x,
      player.position.y,
      player.size.x,
      player.size.y,
    );
    return myRect.overlaps(playerRect);
  }

  void takeHit() {
    health -= 1;
    if (health <= 0) {
      game.onEnemyDefeated(this);
      removeFromParent();
    }
  }

  GamePlatform? platformBelow(double feetY) {
    GamePlatform? best;
    for (final p in game.platforms) {
      final overlapsX = (position.x + size.x > p.position.x) &&
          (position.x < p.position.x + p.size.x);
      if (!overlapsX) continue;
      final top = p.position.y;
      if (top >= feetY - 4 && top <= feetY + 40) {
        best = p;
      }
    }
    return best;
  }

  @override
  void render(Canvas canvas) {
    if (emoji == 'G') {
      _renderGhost(canvas);
    } else if (emoji == 'F') {
      _renderFireImp(canvas);
    } else {
      _renderSlime(canvas);
    }
  }

  void _renderSlime(Canvas canvas) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawOval(Rect.fromLTWH(2, size.y - 3, size.x - 4, 5), shadow);

    canvas.drawOval(
      Rect.fromLTWH(4, 8, size.x - 8, size.y - 8),
      Paint()..color = AppConstants.heroGreen,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.12, 4, size.x * 0.46, size.y * 0.54),
      Paint()..color = const Color(0xFFFFE16A),
    );
    for (final x in [7.0, size.x - 10]) {
      canvas.drawOval(
        Rect.fromLTWH(x, size.y - 8, 7, 5),
        Paint()..color = AppConstants.barkDark,
      );
    }
    for (final x in [size.x * 0.18, size.x * 0.48, size.x * 0.76]) {
      canvas.drawCircle(
        Offset(x, size.y * 0.68),
        2.1,
        Paint()..color = AppConstants.vine.withValues(alpha: 0.85),
      );
    }

    _drawEyes(
      canvas,
      size.x * 0.28,
      size.x * 0.48,
      size.y * 0.34,
      pupilColor: Colors.red.shade900,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.x * 0.28, size.y * 0.47, size.x * 0.2, 5),
      0,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFF10212B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _renderGhost(Canvas canvas) {
    canvas.drawOval(
      Rect.fromLTWH(4, 6, size.x - 8, size.y - 8),
      Paint()..color = AppConstants.foamWhite.withValues(alpha: 0.95),
    );
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.2, size.y * 0.12, size.x * 0.6, size.y * 0.24),
      Paint()..color = AppConstants.accentYellow.withValues(alpha: 0.52),
    );
    for (final x in [size.x * 0.28, size.x * 0.5, size.x * 0.72]) {
      canvas.drawCircle(
        Offset(x, size.y * 0.78),
        3.0,
        Paint()..color = AppConstants.uiDark.withValues(alpha: 0.28),
      );
    }
    _drawEyes(canvas, size.x * 0.38, size.x * 0.62, size.y * 0.44);
  }

  void _renderFireImp(Canvas canvas) {
    final flame = Path()
      ..moveTo(size.x * 0.5, 1)
      ..quadraticBezierTo(size.x * 0.95, size.y * 0.34, size.x * 0.78, size.y)
      ..quadraticBezierTo(size.x * 0.5, size.y * 0.85, size.x * 0.2, size.y)
      ..quadraticBezierTo(size.x * 0.03, size.y * 0.35, size.x * 0.5, 1)
      ..close();
    canvas.drawPath(flame, Paint()..color = AppConstants.fireRed);
    canvas.drawOval(
      Rect.fromLTWH(size.x * 0.3, size.y * 0.34, size.x * 0.4, size.y * 0.45),
      Paint()..color = AppConstants.accentYellow,
    );
    _drawEyes(canvas, size.x * 0.38, size.x * 0.62, size.y * 0.48);
  }

  void _drawEyes(
    Canvas canvas,
    double leftX,
    double rightX,
    double y, {
    Color pupilColor = const Color(0xFF10212B),
  }) {
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = pupilColor;
    canvas.drawCircle(Offset(leftX, y), 4, white);
    canvas.drawCircle(Offset(rightX, y), 4, white);
    canvas.drawCircle(Offset(leftX + 0.7, y + 0.4), 2, ink);
    canvas.drawCircle(Offset(rightX + 0.7, y + 0.4), 2, ink);
  }
}
