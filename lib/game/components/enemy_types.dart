import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
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
          emoji: 'S',
          color: AppConstants.heroGreen,
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
          emoji: 'G',
          color: const Color(0xFFFFC928),
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
          emoji: 'F',
          color: const Color(0xFFFFD734),
          scoreValue: 250,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    final targets = game.activePlayers.toList();
    if (targets.isNotEmpty) {
      targets.sort(
        (a, b) => (a.position - position).length.compareTo(
              (b.position - position).length,
            ),
      );
      final dx = targets.first.position.x - position.x;
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
          emoji: 'B',
          color: AppConstants.accentYellow,
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
    canvas.drawOval(
      Rect.fromLTWH(6, size.y - 5, size.x - 12, 9),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final red = Paint()..color = const Color(0xFFD82822);
    final redDark = Paint()..color = const Color(0xFF8C1F22);
    final white = Paint()..color = const Color(0xFFFFF2DE);
    final ink = Paint()..color = AppConstants.uiDark;

    final tail = Path()
      ..moveTo(9, 38)
      ..quadraticBezierTo(-10, 18, 18, 17)
      ..quadraticBezierTo(28, 28, 18, 42)
      ..close();
    canvas.drawPath(tail, red);
    canvas.drawOval(const Rect.fromLTWH(0, 15, 18, 18), white);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 24, 43, 31),
        const Radius.circular(17),
      ),
      red,
    );
    final stripe = Paint()
      ..color = AppConstants.foamWhite.withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final points in [
      [const Offset(24, 28), const Offset(34, 39)],
      [const Offset(39, 26), const Offset(48, 38)],
      [const Offset(51, 30), const Offset(57, 43)],
    ]) {
      canvas.drawLine(points[0], points[1], stripe);
    }

    for (final leg in [
      const Rect.fromLTWH(23, 48, 8, 17),
      const Rect.fromLTWH(45, 48, 8, 17),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(leg, const Radius.circular(5)),
        redDark,
      );
      canvas.drawOval(
        Rect.fromLTWH(leg.left - 2, leg.bottom - 5, 13, 6),
        white,
      );
    }

    canvas.drawOval(const Rect.fromLTWH(48, 9, 31, 28), red);
    final earLeft = Path()
      ..moveTo(54, 12)
      ..lineTo(57, -4)
      ..lineTo(66, 12)
      ..close();
    final earRight = Path()
      ..moveTo(68, 12)
      ..lineTo(80, -1)
      ..lineTo(78, 17)
      ..close();
    canvas.drawPath(earLeft, red);
    canvas.drawPath(earRight, red);
    canvas.drawPath(
      earLeft,
      Paint()
        ..color = white.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      earRight,
      Paint()
        ..color = white.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawOval(const Rect.fromLTWH(54, 20, 26, 18), white);
    canvas.drawCircle(const Offset(59, 20), 5.2, white);
    canvas.drawCircle(const Offset(72, 20), 5.2, white);
    canvas.drawCircle(const Offset(60.5, 20), 2.3, ink);
    canvas.drawCircle(const Offset(73.5, 20), 2.3, ink);
    canvas.drawOval(const Rect.fromLTWH(75, 27, 5, 4), ink);
    canvas.drawArc(
      const Rect.fromLTWH(64, 29, 13, 7),
      0,
      3.14,
      false,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    const maxHp = 10;
    final hpW = size.x;
    final hpFrac = (health / maxHp).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -22, hpW, 7),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, -22, hpW * hpFrac, 7),
        const Radius.circular(4),
      ),
      Paint()..color = AppConstants.heroGreen,
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
    for (final player in game.activePlayers) {
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
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(
      center,
      size.x / 2,
      Paint()..color = AppConstants.bubbleOrange.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
        center, size.x / 3, Paint()..color = AppConstants.accentYellow);
    canvas.drawCircle(
      Offset(center.dx - 2, center.dy - 2),
      size.x / 7,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }
}
