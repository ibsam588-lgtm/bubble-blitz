import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';
import 'enemy.dart';

class SlimeEnemy extends Enemy {
  double speed = 50;
  int dir = 1;

  SlimeEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(34, 28),
          health: 1,
          emoji: '🟢',
          color: const Color(0xFF66BB6A),
          scoreValue: 100,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    position.x += speed * dir * dt;

    // Apply gravity
    position.y += 200 * dt;
    final feetY = position.y + size.y;
    final plat = platformBelow(feetY);
    if (plat != null && position.y + size.y > plat.position.y) {
      position.y = plat.position.y - size.y;
    }

    // Reverse on platform edge or wall
    if (plat != null) {
      final left = position.x;
      final right = position.x + size.x;
      if (right > plat.position.x + plat.size.x) {
        dir = -1;
      } else if (left < plat.position.x) {
        dir = 1;
      }
    }
    if (position.x < 0) {
      position.x = 0;
      dir = 1;
    }
    if (position.x + size.x > game.worldSize.x) {
      position.x = game.worldSize.x - size.x;
      dir = -1;
    }
  }
}

class GhostEnemy extends Enemy {
  double t = 0;
  double startY;
  double startX;
  double driftDir = 1;

  GhostEnemy({required Vector2 position})
      : startY = position.y,
        startX = position.x,
        super(
          position: position,
          size: Vector2(34, 34),
          health: 2,
          emoji: '👻',
          color: const Color(0xFFE0E0E0),
          scoreValue: 200,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    t += dt;
    position.y = startY + math.sin(t * 2.5) * 40;
    position.x += 30 * driftDir * dt;
    if (position.x < 20 || position.x > game.worldSize.x - 40) {
      driftDir = -driftDir;
    }
  }
}

class FireImpEnemy extends Enemy {
  double shootTimer = 2;

  FireImpEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 32),
          health: 1,
          emoji: '🔥',
          color: const Color(0xFFEF5350),
          scoreValue: 250,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    final player = game.player;
    if (player != null) {
      final dx = player.position.x - position.x;
      position.x += dx.sign * 25 * dt;
    }

    // Gravity to settle on platforms
    position.y += 200 * dt;
    final feetY = position.y + size.y;
    final plat = platformBelow(feetY);
    if (plat != null && position.y + size.y > plat.position.y) {
      position.y = plat.position.y - size.y;
    }

    shootTimer -= dt;
    if (shootTimer <= 0) {
      shootTimer = 2.5;
      game.spawnEnemyProjectile(this);
    }
  }
}

class BossEnemy extends Enemy {
  double t = 0;
  double spawnTimer = 4.0;
  double dirX = 1;

  BossEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(80, 70),
          health: 10,
          emoji: '👹',
          color: const Color(0xFF8E24AA),
          scoreValue: 2000,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    t += dt;
    position.x += 40 * dirX * dt;
    position.y = 180 + math.sin(t * 1.6) * 20;
    if (position.x < 20) {
      position.x = 20;
      dirX = 1;
    }
    if (position.x + size.x > game.worldSize.x - 20) {
      position.x = game.worldSize.x - 20 - size.x;
      dirX = -1;
    }

    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawnTimer = 5.0;
      game.spawnMinion(this);
    }
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, Paint()..color = color);

    // Horns
    final hornPaint = Paint()..color = Colors.red.shade900;
    final left = Path()
      ..moveTo(10, 0)
      ..lineTo(20, -10)
      ..lineTo(28, 0)
      ..close();
    final right = Path()
      ..moveTo(size.x - 28, 0)
      ..lineTo(size.x - 20, -10)
      ..lineTo(size.x - 10, 0)
      ..close();
    canvas.drawPath(left, hornPaint);
    canvas.drawPath(right, hornPaint);

    // Eyes
    final eyePaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 6, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 6, eyePaint);
    canvas.drawCircle(Offset(size.x * 0.3, size.y * 0.4), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(size.x * 0.7, size.y * 0.4), 3, Paint()..color = Colors.black);

    // Mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final mouthPath = Path()
      ..moveTo(size.x * 0.25, size.y * 0.7)
      ..quadraticBezierTo(size.x * 0.5, size.y * 0.85, size.x * 0.75, size.y * 0.7);
    canvas.drawPath(mouthPath, mouthPaint);

    // Health bar
    final maxHp = 10;
    final hpW = size.x;
    final hpFrac = (health / maxHp).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(0, -22, hpW, 6),
      Paint()..color = Colors.black54,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -22, hpW * hpFrac, 6),
      Paint()..color = Colors.greenAccent.shade400,
    );
  }
}

class EnemyProjectile extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  double vx;
  double vy;
  double life = 3;

  EnemyProjectile({
    required Vector2 position,
    required this.vx,
    required this.vy,
  }) : super(position: position, size: Vector2(12, 12), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position.x += vx * dt;
    position.y += vy * dt;
    vy += 200 * dt;
    life -= dt;
    if (life <= 0 ||
        position.y > game.worldSize.y ||
        position.x < -20 ||
        position.x > game.worldSize.x + 20) {
      removeFromParent();
      return;
    }
    final player = game.player;
    if (player != null) {
      final rect = Rect.fromLTWH(
        position.x - size.x / 2,
        position.y - size.y / 2,
        size.x,
        size.y,
      );
      final pr = Rect.fromLTWH(
        player.position.x,
        player.position.y,
        player.size.x,
        player.size.y,
      );
      if (rect.overlaps(pr)) {
        player.hit();
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.orange,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 4,
      Paint()..color = Colors.yellow,
    );
  }
}
