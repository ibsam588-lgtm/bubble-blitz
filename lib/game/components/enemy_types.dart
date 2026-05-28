import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';
import 'enemy.dart';

// ── SlimeEnemy ────────────────────────────────────────────────────────────────

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

    position.y += 200 * dt;
    final feetY = position.y + size.y;
    final plat = platformBelow(feetY);
    if (plat != null && position.y + size.y > plat.position.y) {
      position.y = plat.position.y - size.y;
    }

    if (plat != null) {
      if (position.x + size.x > plat.position.x + plat.size.x) dir = -1;
      else if (position.x < plat.position.x) dir = 1;
    }
    if (position.x < 0) { position.x = 0; dir = 1; }
    if (position.x + size.x > game.worldSize.x) { position.x = game.worldSize.x - size.x; dir = -1; }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Main blob body
    canvas.drawOval(Rect.fromLTWH(2, 4, 30, 22), Paint()..color = const Color(0xFF66BB6A));
    // Lighter belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 19, height: 14),
      Paint()..color = const Color(0xFFA5D6A7),
    );

    // Beady eyes
    canvas.drawCircle(Offset(cx - 6, cy - 2), 4.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 6, cy - 2), 4.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 5.0, cy - 2), 2.6, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx + 7.0, cy - 2), 2.6, Paint()..color = Colors.black);
    // Eye shines
    canvas.drawCircle(Offset(cx - 6.5, cy - 4), 1.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 5.5, cy - 4), 1.0, Paint()..color = Colors.white);

    // Smile
    final mouthPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final mp = Path()
      ..moveTo(cx - 5, cy + 5)
      ..quadraticBezierTo(cx, cy + 9, cx + 5, cy + 5);
    canvas.drawPath(mp, mouthPaint);

    // Dark outline
    canvas.drawOval(
      Rect.fromLTWH(2, 4, 30, 22),
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── GhostEnemy ────────────────────────────────────────────────────────────────

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
    if (position.x < 20 || position.x > game.worldSize.x - 40) driftDir = -driftDir;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final alpha = isTrapped ? 0.45 : 0.82;

    // Teardrop body path
    final path = Path();
    path.moveTo(cx, 4);
    path.cubicTo(cx + 15, 4, cx + 17, 16, cx + 17, 22);
    path.cubicTo(cx + 17, 28, cx + 13, 30, cx + 9, 28);
    // Wavy bottom skirt
    path.quadraticBezierTo(cx + 4,  size.y - 1, cx,      size.y - 5);
    path.quadraticBezierTo(cx - 4,  size.y - 1, cx - 9,  28);
    path.cubicTo(cx - 13, 30, cx - 17, 28, cx - 17, 22);
    path.cubicTo(cx - 17, 16, cx - 15, 4, cx, 4);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: alpha));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blueGrey.shade300.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Hollow dark eyes
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 6, 16), width: 10, height: 11),
      Paint()..color = Colors.blueGrey.shade800,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, 16), width: 10, height: 11),
      Paint()..color = Colors.blueGrey.shade800,
    );
    // Inner glow highlights
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, 13), width: 4, height: 4),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 4, 13), width: 4, height: 4),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── FireImpEnemy ──────────────────────────────────────────────────────────────

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
    position.y += 200 * dt;
    final feetY = position.y + size.y;
    final plat = platformBelow(feetY);
    if (plat != null && position.y + size.y > plat.position.y) {
      position.y = plat.position.y - size.y;
    }
    shootTimer -= dt;
    if (shootTimer <= 0) { shootTimer = 2.5; game.spawnEnemyProjectile(this); }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Devil horns
    final hornPaint = Paint()..color = const Color(0xFFB71C1C);
    final leftHorn = Path()
      ..moveTo(cx - 10, 8)
      ..lineTo(cx - 15, 0)
      ..lineTo(cx - 6,  8)
      ..close();
    final rightHorn = Path()
      ..moveTo(cx + 6,  8)
      ..lineTo(cx + 15, 0)
      ..lineTo(cx + 10, 8)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);
    canvas.drawPath(rightHorn, hornPaint);

    // Round body
    canvas.drawOval(Rect.fromLTWH(2, 6, 28, 24), Paint()..color = const Color(0xFFEF5350));
    // Lighter belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 17, height: 14),
      Paint()..color = const Color(0xFFFF8A65),
    );

    // Glowing eyes — aura ring + yellow iris + red pupil
    for (final ex in [cx - 6.0, cx + 6.0]) {
      canvas.drawCircle(
        Offset(ex, cy - 2), 6.5,
        Paint()..color = const Color(0xFFFF6F00).withValues(alpha: 0.35),
      );
      canvas.drawCircle(Offset(ex, cy - 2), 4.5, Paint()..color = const Color(0xFFFFEB3B));
      canvas.drawCircle(Offset(ex, cy - 1), 2.2, Paint()..color = const Color(0xFFB71C1C));
    }

    // Body outline
    canvas.drawOval(
      Rect.fromLTWH(2, 6, 28, 24),
      Paint()
        ..color = const Color(0xFF7F0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── BossEnemy ─────────────────────────────────────────────────────────────────

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
    if (position.x < 20) { position.x = 20; dirX = 1; }
    if (position.x + size.x > game.worldSize.x - 20) {
      position.x = game.worldSize.x - 20 - size.x; dirX = -1;
    }
    spawnTimer -= dt;
    if (spawnTimer <= 0) { spawnTimer = 5.0; game.spawnMinion(this); }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // ── Health bar above boss ──
    const maxHp = 10;
    final hpFrac = (health / maxHp).clamp(0.0, 1.0);
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, -26, size.x, 9), const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
    // Fill gradient
    final hpShader = LinearGradient(
      colors: [const Color(0xFFFF1744), const Color(0xFF69F0AE)],
    ).createShader(Rect.fromLTWH(0, -26, size.x, 9));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, -26, size.x * hpFrac, 9), const Radius.circular(4)),
      Paint()..shader = hpShader,
    );
    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, -26, size.x, 9), const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── Golden crown ──
    final crownPaint = Paint()..color = const Color(0xFFFFD600);
    final crownOutline = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final crown = Path();
    // Crown band
    crown.addRect(Rect.fromLTWH(cx - 18, -14, 36, 8));
    // Three spikes
    crown.moveTo(cx - 18, -14);
    crown.lineTo(cx - 24, -24);
    crown.lineTo(cx - 12, -14);
    crown.moveTo(cx, -14);
    crown.lineTo(cx, -28);
    crown.lineTo(cx + 12, -14);
    crown.moveTo(cx + 18, -14);
    crown.lineTo(cx + 24, -24);
    crown.lineTo(cx + 12, -14);
    canvas.drawPath(crown, crownPaint);
    canvas.drawPath(crown, crownOutline);
    // Crown gems
    canvas.drawCircle(Offset(cx - 18, -10), 3, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(Offset(cx,       -10), 3, Paint()..color = const Color(0xFF1E88E5));
    canvas.drawCircle(Offset(cx + 18,  -10), 3, Paint()..color = const Color(0xFF43A047));

    // ── Main dragon-like body ──
    canvas.drawOval(
      Rect.fromLTWH(4, 8, size.x - 8, size.y - 12),
      Paint()..color = const Color(0xFF8E24AA),
    );
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 44, height: 34),
      Paint()..color = const Color(0xFFBA68C8),
    );

    // Large curved horns
    final hornP = Paint()..color = const Color(0xFF6A1B9A);
    final lHorn = Path()
      ..moveTo(cx - 20, 10)
      ..lineTo(cx - 30, -6)
      ..lineTo(cx - 16, 8)
      ..close();
    final rHorn = Path()
      ..moveTo(cx + 20, 10)
      ..lineTo(cx + 30, -6)
      ..lineTo(cx + 16, 8)
      ..close();
    canvas.drawPath(lHorn, hornP);
    canvas.drawPath(rHorn, hornP);

    // Large glowing eyes
    for (final ex in [cx - 14.0, cx + 14.0]) {
      canvas.drawCircle(Offset(ex, cy - 4), 9, Paint()..color = const Color(0xFFFFEB3B));
      canvas.drawCircle(Offset(ex, cy - 3), 5.5, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(ex - 2, cy - 6), 2, Paint()..color = Colors.white);
    }

    // Snarling mouth
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final mouthPath = Path()
      ..moveTo(cx - 18, cy + 14)
      ..quadraticBezierTo(cx, cy + 24, cx + 18, cy + 14);
    canvas.drawPath(mouthPath, mouthPaint);
    // Fangs
    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + 16)
        ..lineTo(cx - 6, cy + 22)
        ..lineTo(cx - 4, cy + 16),
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 4,  cy + 16)
        ..lineTo(cx + 6,  cy + 22)
        ..lineTo(cx + 8,  cy + 16),
      Paint()..color = Colors.white,
    );

    // Body outline
    canvas.drawOval(
      Rect.fromLTWH(4, 8, size.x - 8, size.y - 12),
      Paint()
        ..color = const Color(0xFF4A148C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── EnemyProjectile ───────────────────────────────────────────────────────────

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
        position.x - size.x / 2, position.y - size.y / 2, size.x, size.y);
      final pr = Rect.fromLTWH(
        player.position.x, player.position.y, player.size.x, player.size.y);
      if (rect.overlaps(pr)) { player.hit(); removeFromParent(); }
    }
  }

  @override
  void render(Canvas canvas) {
    // Fiery orb
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2), size.x / 2,
      Paint()..color = const Color(0xFFFF6F00),
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2), size.x / 3.5,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2), size.x / 6,
      Paint()..color = Colors.white,
    );
  }
}
