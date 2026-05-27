import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';
import 'enemy.dart';

class Bubble extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  double vx;
  double vy;
  double lifetime;
  bool isBig;
  Enemy? trappedEnemy;
  bool floating = false;
  double bounces = 0;

  Bubble({
    required Vector2 position,
    required this.vx,
    this.vy = 0,
    this.lifetime = AppConstants.bubbleLifetime,
    this.isBig = false,
  }) : super(
          position: position,
          size: Vector2(isBig ? 36 : 24, isBig ? 36 : 24),
          anchor: Anchor.center,
        );

  double get radius => size.x / 2;

  @override
  void update(double dt) {
    super.update(dt);

    if (floating) {
      position.y += AppConstants.trappedBubbleRise * dt;
      position.x += math.sin(lifetime * 3) * 0.4;
      lifetime -= dt;
      trappedEnemy?.position = position - trappedEnemy!.size / 2;
      if (lifetime <= 0) {
        _popUntrapped();
      }
      if (position.y < -40) {
        removeFromParent();
      }
      return;
    }

    position.x += vx * dt;
    vy += 60 * dt; // slight gravity
    position.y += vy * dt;
    lifetime -= dt;

    // Bounce off walls
    if (position.x < radius) {
      position.x = radius;
      vx = -vx;
      bounces += 1;
    }
    if (position.x > game.worldSize.x - radius) {
      position.x = game.worldSize.x - radius;
      vx = -vx;
      bounces += 1;
    }
    if (position.y > game.worldSize.y - radius) {
      removeFromParent();
      return;
    }

    if (lifetime <= 0 || bounces > 4) {
      removeFromParent();
      return;
    }

    // Try to trap an enemy
    for (final enemy in game.enemies.toList()) {
      if (enemy.isTrapped) continue;
      final dx = position.x - (enemy.position.x + enemy.size.x / 2);
      final dy = position.y - (enemy.position.y + enemy.size.y / 2);
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < radius + enemy.size.x * 0.5) {
        _trap(enemy);
        return;
      }
    }
  }

  void _trap(Enemy enemy) {
    enemy.onTrapped();
    trappedEnemy = enemy;
    floating = true;
    vx = 0;
    vy = 0;
    lifetime = 4.0;
  }

  void popByPlayer() {
    if (trappedEnemy != null) {
      game.onEnemyDefeated(trappedEnemy!);
      trappedEnemy!.removeFromParent();
    }
    game.spawnPopEffect(position.clone());
    removeFromParent();
  }

  void _popUntrapped() {
    // Trapped bubble timed out → enemy escapes
    trappedEnemy?.onEscape();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);

    final outerPaint = Paint()
      ..color = AppConstants.bubbleBlue.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, ringPaint);

    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(
      Offset(radius - radius * 0.4, radius - radius * 0.4),
      radius * 0.25,
      highlight,
    );

    if (trappedEnemy != null) {
      final tp = TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      tp.render(canvas, trappedEnemy!.emoji, Vector2(radius - 8, radius - 10));
    }
  }
}
