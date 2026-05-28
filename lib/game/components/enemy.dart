import 'package:flame/components.dart';
import 'package:flutter/material.dart';

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

  void onTrapped() { isTrapped = true; }
  void onEscape()  { isTrapped = false; }

  bool checkPlayerCollision(Player player) {
    if (isTrapped) return false;
    final myRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    final playerRect = Rect.fromLTWH(
      player.position.x, player.position.y, player.size.x, player.size.y);
    return myRect.overlaps(playerRect);
  }

  void takeHit() {
    health -= 1;
    if (health <= 0) { game.onEnemyDefeated(this); removeFromParent(); }
  }

  GamePlatform? platformBelow(double feetY) {
    GamePlatform? best;
    for (final p in game.platforms) {
      final overlapsX = (position.x + size.x > p.position.x) &&
          (position.x < p.position.x + p.size.x);
      if (!overlapsX) continue;
      final top = p.position.y;
      if (top >= feetY - 4 && top <= feetY + 40) best = p;
    }
    return best;
  }

  // Called by subclasses when trapped to draw a light bubble overlay.
  void drawTrappedOverlay(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)),
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(10)),
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  void render(Canvas canvas) {
    // Fallback rendering (subclasses override this)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = color);
    if (isTrapped) drawTrappedOverlay(canvas);
  }
}
