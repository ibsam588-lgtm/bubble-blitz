import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bubble_blitz_game.dart';
import 'enemy.dart';

// ── Mighta (SlimeEnemy) ───────────────────────────────────────────────────────
// Classic BB2 round green creature with a large eye stalk

class SlimeEnemy extends Enemy {
  double speed = 50;
  int dir = 1;
  double _t = 0;

  SlimeEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(34, 36),
          health: 1,
          emoji: '👁',
          color: const Color(0xFF43A86E),
          scoreValue: 100,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
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
    if (position.x + size.x > game.worldSize.x) {
      position.x = game.worldSize.x - size.x; dir = -1;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2 + 4;

    // ── Eye stalk (drawn first so body covers base) ──
    final eyeSway = math.sin(_t * 2.8) * 3.0;
    final stalkTop = Offset(cx + eyeSway, 4.0);
    // Stalk
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - 10)
        ..quadraticBezierTo(cx + eyeSway * 0.5, cy - 18, stalkTop.dx, stalkTop.dy),
      Paint()
        ..color = const Color(0xFF2E7D55)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke,
    );
    // Stalk outline
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - 10)
        ..quadraticBezierTo(cx + eyeSway * 0.5, cy - 18, stalkTop.dx, stalkTop.dy),
      Paint()
        ..color = const Color(0xFF1A4A30)
        ..strokeWidth = 4.8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - 10)
        ..quadraticBezierTo(cx + eyeSway * 0.5, cy - 18, stalkTop.dx, stalkTop.dy),
      Paint()
        ..color = const Color(0xFF2E7D55)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke,
    );

    // ── Round body ──
    canvas.drawCircle(Offset(cx, cy), 13, Paint()..color = const Color(0xFF43A86E));
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 16, height: 12),
      Paint()..color = const Color(0xFF8ED4A4),
    );
    // Body outline
    canvas.drawCircle(
      Offset(cx, cy),
      13,
      Paint()
        ..color = const Color(0xFF1A4A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── Tiny feet nubs ──
    for (final fx in [cx - 7.0, cx + 7.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, cy + 12), width: 9, height: 6),
        Paint()..color = const Color(0xFF2E7D55),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, cy + 12), width: 9, height: 6),
        Paint()
          ..color = const Color(0xFF1A4A30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // ── Mouth (cute smile) ──
    final smilePaint = Paint()
      ..color = const Color(0xFF1A4A30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 5, cy + 6)
        ..quadraticBezierTo(cx, cy + 10, cx + 5, cy + 6),
      smilePaint,
    );

    // ── Eye stalk bulb ──
    canvas.drawCircle(stalkTop, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      stalkTop, 6.5,
      Paint()
        ..color = const Color(0xFF1A4A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(stalkTop + const Offset(1, 1), 4, Paint()..color = Colors.black);
    canvas.drawCircle(stalkTop + const Offset(-1.5, -1.5), 1.5, Paint()..color = Colors.white);

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── Blubba (GhostEnemy) ───────────────────────────────────────────────────────
// Electric floating eye monster — large central eye with lightning aura

class GhostEnemy extends Enemy {
  double t = 0;
  double startY;
  double driftDir = 1;

  GhostEnemy({required Vector2 position})
      : startY = position.y,
        super(
          position: position,
          size: Vector2(36, 36),
          health: 2,
          emoji: '⚡',
          color: const Color(0xFFB388FF),
          scoreValue: 200,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    t += dt;
    position.y = startY + math.sin(t * 2.5) * 40;
    position.x += 35 * driftDir * dt;
    if (position.x < 20 || position.x > game.worldSize.x - 44) {
      driftDir = -driftDir;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = (math.sin(t * 5) + 1) / 2;

    // ── Electric aura rings ──
    for (int i = 3; i >= 1; i--) {
      final auraR = 14.0 + i * 3.5 + pulse * 2;
      canvas.drawCircle(
        Offset(cx, cy),
        auraR,
        Paint()
          ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.15 - i * 0.03),
      );
    }

    // ── Round body ──
    canvas.drawCircle(
      Offset(cx, cy), 14,
      Paint()
        ..color = const Color(0xFFCE93D8).withValues(alpha: 0.85));
    // Belly tint
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 17, height: 13),
      Paint()..color = const Color(0xFFF3E5F5).withValues(alpha: 0.6),
    );
    // Body outline
    canvas.drawCircle(
      Offset(cx, cy), 14,
      Paint()
        ..color = const Color(0xFF4A148C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── HUGE central eye ──
    canvas.drawCircle(Offset(cx, cy - 2), 9, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy - 2), 9,
        Paint()
          ..color = const Color(0xFF4A148C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Iris (electric purple)
    canvas.drawCircle(Offset(cx, cy - 2), 5.5,
        Paint()..color = const Color(0xFF7C4DFF));
    // Pupil
    canvas.drawCircle(Offset(cx, cy - 2), 3.2, Paint()..color = Colors.black);
    // Eye shine
    canvas.drawCircle(Offset(cx - 2.5, cy - 5), 2.0, Paint()..color = Colors.white);

    // ── Lightning bolt decorations ──
    _drawLightning(canvas, cx - 14, cy - 4, dir: -1, pulse: pulse);
    _drawLightning(canvas, cx + 14, cy - 4, dir: 1, pulse: pulse);

    // ── Wavy ghost skirt bottom ──
    final skirtPath = Path()..moveTo(cx - 13, cy + 10);
    for (int i = 0; i <= 4; i++) {
      final sx = (cx - 13) + i * 6.5;
      final sy = cy + 14 + (i.isEven ? 4 : -2);
      skirtPath.lineTo(sx, sy);
    }
    skirtPath.lineTo(cx + 13, cy + 10);
    canvas.drawPath(
        skirtPath,
        Paint()
          ..color = const Color(0xFFCE93D8).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill);

    if (isTrapped) drawTrappedOverlay(canvas);
  }

  void _drawLightning(
      Canvas canvas, double x, double y, {required double dir, required double pulse}) {
    final paint = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.6 + pulse * 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + dir * 5, y)
        ..lineTo(x, y + 2)
        ..lineTo(x + dir * 5, y + 7),
      paint,
    );
  }
}

// ── Drunk (FireImpEnemy) ──────────────────────────────────────────────────────
// Round pink/orange creature — BB2 "Drunk" style

class FireImpEnemy extends Enemy {
  double shootTimer = 2;
  double _t = 0;

  FireImpEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(34, 34),
          health: 1,
          emoji: '🔥',
          color: const Color(0xFFFF7043),
          scoreValue: 250,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (isTrapped) return;
    final player = game.player;
    if (player != null) {
      final dx = player.position.x - position.x;
      position.x += dx.sign * 28 * dt;
    }
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

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2 + 1;
    final rosy = (math.sin(_t * 3) + 1) / 2;

    // ── Ear/cheek puffs ──
    for (final ex in [cx - 14.0, cx + 14.0]) {
      canvas.drawCircle(Offset(ex, cy + 2), 7, Paint()..color = const Color(0xFFFF8A65));
      canvas.drawCircle(Offset(ex, cy + 2), 7,
          Paint()
            ..color = const Color(0xFFBF360C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    // ── Round body ──
    canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = const Color(0xFFFF7043));
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 18, height: 14),
      Paint()..color = const Color(0xFFFFCCBC),
    );
    // Rosy cheek tint
    canvas.drawCircle(Offset(cx - 6, cy + 5), 5,
        Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.25 + rosy * 0.15));
    canvas.drawCircle(Offset(cx + 6, cy + 5), 5,
        Paint()..color = const Color(0xFFE53935).withValues(alpha: 0.25 + rosy * 0.15));

    // ── Body outline ──
    canvas.drawCircle(Offset(cx, cy), 14,
        Paint()
          ..color = const Color(0xFFBF360C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);

    // ── Curly horns ──
    for (final hx in [cx - 6.0, cx + 6.0]) {
      final xSign = hx < cx ? -1.0 : 1.0;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(hx, cy - 13), width: 12, height: 10),
        xSign > 0 ? -math.pi * 0.9 : -math.pi * 0.1,
        math.pi * 0.85,
        false,
        Paint()
          ..color = const Color(0xFFBF360C)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke,
      );
    }

    // ── Big angry eyes ──
    for (final ex in [cx - 6.5, cx + 6.5]) {
      // Angry brow line
      final xSign = ex < cx ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(ex - xSign * 5, cy - 9),
        Offset(ex + xSign * 2, cy - 7),
        Paint()
          ..color = const Color(0xFF7F0000)
          ..strokeWidth = 2.0,
      );
      // Eye white
      canvas.drawCircle(Offset(ex, cy - 4), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(ex, cy - 4), 5.5,
          Paint()
            ..color = const Color(0xFF7F0000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      // Yellow iris with red pupil
      canvas.drawCircle(Offset(ex, cy - 3.5), 3.2,
          Paint()..color = const Color(0xFFFFD740));
      canvas.drawCircle(Offset(ex + xSign * 0.5, cy - 3), 1.8,
          Paint()..color = const Color(0xFFB71C1C));
    }

    // ── Open fanged mouth ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 9), width: 14, height: 9),
      Paint()..color = const Color(0xFFB71C1C),
    );
    // Fangs
    for (final fx in [cx - 3.5, cx + 3.5]) {
      canvas.drawPath(
        Path()
          ..moveTo(fx - 2, cy + 5)
          ..lineTo(fx, cy + 9)
          ..lineTo(fx + 2, cy + 5),
        Paint()..color = Colors.white,
      );
    }

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── Super Drunk / Boss ────────────────────────────────────────────────────────
// Giant crowned eye creature — BB2 final boss style

class BossEnemy extends Enemy {
  double t = 0;
  double spawnTimer = 4.0;
  double dirX = 1;

  BossEnemy({required Vector2 position})
      : super(
          position: position,
          size: Vector2(84, 76),
          health: 10,
          emoji: '👹',
          color: const Color(0xFF6A1B9A),
          scoreValue: 2000,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isTrapped) return;
    t += dt;
    position.x += 42 * dirX * dt;
    position.y = 180 + math.sin(t * 1.6) * 22;
    if (position.x < 20) { position.x = 20; dirX = 1; }
    if (position.x + size.x > game.worldSize.x - 20) {
      position.x = game.worldSize.x - 20 - size.x;
      dirX = -1;
    }
    spawnTimer -= dt;
    if (spawnTimer <= 0) { spawnTimer = 5.0; game.spawnMinion(this); }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2 + 4;
    final pulse = (math.sin(t * 3.5) + 1) / 2;

    // ── Health bar ──
    const maxHp = 10;
    final hpFrac = (health / maxHp).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, -26, size.x, 9), const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );
    final hpShader = LinearGradient(
      colors: [const Color(0xFFFF1744), const Color(0xFF00E676)],
    ).createShader(Rect.fromLTWH(0, -26, size.x, 9));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, -26, size.x * hpFrac, 9), const Radius.circular(4)),
      Paint()..shader = hpShader,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, -26, size.x, 9), const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── Pulsing aura ──
    canvas.drawCircle(
      Offset(cx, cy - 4),
      30 + pulse * 6,
      Paint()
        ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.12 + pulse * 0.06),
    );

    // ── Big round body (purple) ──
    canvas.drawCircle(
      Offset(cx, cy), 30, Paint()..color = const Color(0xFF7B1FA2));
    // Belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 38, height: 30),
      Paint()..color = const Color(0xFFCE93D8),
    );
    // Body outline
    canvas.drawCircle(
      Offset(cx, cy), 30,
      Paint()
        ..color = const Color(0xFF38006B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // ── Golden crown ──
    final crownPaint = Paint()..color = const Color(0xFFFFD600);
    final crownOutlinePaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    // Crown band
    final crown = Path();
    crown.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, cy - 34, 40, 10), const Radius.circular(2)));
    // Three spikes
    crown.moveTo(cx - 20, cy - 34);
    crown.lineTo(cx - 27, cy - 46);
    crown.lineTo(cx - 14, cy - 34);
    crown.moveTo(cx - 2, cy - 34);
    crown.lineTo(cx, cy - 52);
    crown.lineTo(cx + 12, cy - 34);
    crown.moveTo(cx + 20, cy - 34);
    crown.lineTo(cx + 27, cy - 46);
    crown.lineTo(cx + 14, cy - 34);
    canvas.drawPath(crown, crownPaint);
    canvas.drawPath(crown, crownOutlinePaint);
    // Crown gems
    canvas.drawCircle(Offset(cx - 18, cy - 30), 3.5, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(Offset(cx, cy - 30), 3.5, Paint()..color = const Color(0xFF1E88E5));
    canvas.drawCircle(Offset(cx + 18, cy - 30), 3.5, Paint()..color = const Color(0xFF43A047));

    // ── Large curved horns ──
    final hornP = Paint()
      ..color = const Color(0xFF4A148C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 22, cy - 20), width: 24, height: 20),
      -math.pi * 0.8, math.pi * 0.7, false, hornP);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 22, cy - 20), width: 24, height: 20),
      -math.pi * 0.2, -math.pi * 0.7, false, hornP);

    // ── Pair of HUGE glowing eyes ──
    for (final exOff in [-14.0, 14.0]) {
      final ex = cx + exOff;
      final ey = cy - 8.0;
      // Glow ring
      canvas.drawCircle(Offset(ex, ey), 11,
          Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: 0.3 + pulse * 0.2));
      // Sclera
      canvas.drawCircle(Offset(ex, ey), 9, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(ex, ey), 9,
          Paint()
            ..color = const Color(0xFF38006B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      // Iris
      canvas.drawCircle(Offset(ex, ey + 0.5), 5.5,
          Paint()..color = const Color(0xFFFFE57F));
      // Pupil
      canvas.drawCircle(Offset(ex, ey + 1), 3.0, Paint()..color = Colors.black);
      // Shine
      canvas.drawCircle(Offset(ex - 2.5, ey - 3), 2.0, Paint()..color = Colors.white);
    }

    // ── Snarling mouth with fangs ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 30, height: 16),
      Paint()..color = Colors.black,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 18), width: 28, height: 10),
      Paint()..color = const Color(0xFFE53935),
    );
    for (final fx in [cx - 8.0, cx + 8.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(fx - 3, cy + 14)
          ..lineTo(fx, cy + 21)
          ..lineTo(fx + 3, cy + 14),
        Paint()..color = Colors.white,
      );
    }

    if (isTrapped) drawTrappedOverlay(canvas);
  }
}

// ── EnemyProjectile ───────────────────────────────────────────────────────────

class EnemyProjectile extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  double vx;
  double vy;
  double life = 3;
  double _t = 0;

  EnemyProjectile({
    required Vector2 position,
    required this.vx,
    required this.vy,
  }) : super(position: position, size: Vector2(14, 14), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
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
      if (rect.overlaps(pr)) {
        player.hit();
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = (math.sin(_t * 8) + 1) / 2;

    // Outer glow
    canvas.drawCircle(Offset(cx, cy), size.x / 2 + 2,
        Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.35 + pulse * 0.25));
    // Fiery orb
    canvas.drawCircle(Offset(cx, cy), size.x / 2,
        Paint()..color = const Color(0xFFFF6D00));
    // Inner bright core
    canvas.drawCircle(Offset(cx, cy), size.x / 3.0,
        Paint()..color = const Color(0xFFFFE57F));
    // Hot center
    canvas.drawCircle(Offset(cx, cy), size.x / 6.0,
        Paint()..color = Colors.white);
  }
}
