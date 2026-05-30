import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world/level_data.dart';

/// BB2-style stone + grass platform used for every world.
class GamePlatform extends PositionComponent {
  final PlatformSpec spec;
  final Color color;
  final int world;
  double _t = 0;
  late final double _startX;
  late final List<_Stone> _stones;

  GamePlatform({required this.spec, required this.color, required this.world})
      : super(
          position: Vector2(spec.x, spec.y),
          size: Vector2(spec.width, spec.height),
        ) {
    _startX = spec.x;
    _stones = _buildStones();
  }

  /// Pre-compute random stone-block subdivision for visual variety.
  List<_Stone> _buildStones() {
    final rand = math.Random((spec.x * 7 + spec.y * 13).toInt().abs());
    final stones = <_Stone>[];
    double x = 0;
    const minW = 18.0;
    const maxW = 32.0;
    while (x < spec.width) {
      final remaining = spec.width - x;
      // The final sliver can be narrower than minW. We must NOT clamp(minW,
      // remaining) in that case because num.clamp throws ArgumentError when
      // lowerLimit > upperLimit (even in release) — this was crashing level
      // load and showing a blank/grey screen. Just fill the remaining width.
      final double w = remaining <= minW
          ? remaining
          : (minW + rand.nextDouble() * (maxW - minW)).clamp(minW, remaining);
      stones.add(_Stone(x: x, w: w, shade: rand.nextDouble()));
      x += w;
    }
    return stones;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (spec.moving) {
      position.x = _startX + (spec.moveRange * 0.5) * (1 + math.sin(_t * 1.6));
    }
  }

  @override
  void render(Canvas canvas) {
    _renderBB2Stone(canvas);
  }

  void _renderBB2Stone(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // ── Outer dark shadow / depth ──────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 3, w, h), const Radius.circular(4)),
      Paint()..color = const Color(0x55000000),
    );

    // ── Draw individual stone blocks ───────────────────────────────────────
    for (final s in _stones) {
      _renderStoneBlock(canvas, s.x, 0, s.w, h, s.shade);
    }

    // ── Lush green grass cap on top ────────────────────────────────────────
    // Base grass fill
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, 8),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF3EC64E),
    );
    // Bright highlight stripe at very top
    canvas.drawLine(
      const Offset(3, 1.5),
      Offset(w - 3, 1.5),
      Paint()
        ..color = const Color(0xFF7EFF8E)
        ..strokeWidth = 2.0,
    );
    // Grass bumps
    final bumpPaint = Paint()..color = const Color(0xFF2DA040);
    for (double bx = 5; bx < w - 2; bx += 10) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, 0), width: 8, height: 5),
        bumpPaint,
      );
    }

    // ── Thick dark outline ─────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h), const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF172830)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // ── Moving platform shimmer pulse ──────────────────────────────────────
    if (spec.moving) {
      final alpha = ((math.sin(_t * 4) + 1) / 2) * 0.22;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), const Radius.circular(4)),
        Paint()..color = const Color(0xFF90FF9E).withValues(alpha: alpha),
      );
    }
  }

  void _renderStoneBlock(
      Canvas canvas, double bx, double by, double bw, double bh, double shade) {
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3));

    // Stone base — slight shade variation per block
    final baseGray = (0x5C + (shade * 14).toInt()).clamp(0, 255);
    final blueShift = (0x6A + (shade * 12).toInt()).clamp(0, 255);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Color.fromARGB(255, baseGray, baseGray + 8, blueShift),
    );

    // Inner lighter top-left bevel (gives 3D depth)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + 2, by + 8, bw - 4, 3), const Radius.circular(1)),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // Diamond scale texture lines
    final texPaint = Paint()
      ..color = const Color(0xFF3A5060).withValues(alpha: 0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    const step = 10.0;
    for (double ty = 8; ty < bh - 2; ty += step * 0.65) {
      for (double tx = bx; tx < bx + bw - step; tx += step) {
        canvas.drawPath(
          Path()
            ..moveTo(tx + step / 2, ty)
            ..lineTo(tx + step, ty + step * 0.32)
            ..lineTo(tx + step / 2, ty + step * 0.65)
            ..lineTo(tx, ty + step * 0.32)
            ..close(),
          texPaint,
        );
      }
    }

    // Vertical mortar joint between blocks
    if (bx > 0) {
      canvas.drawLine(
        Offset(bx, by + 8),
        Offset(bx, by + bh),
        Paint()
          ..color = const Color(0xFF1A2C38)
          ..strokeWidth = 1.2,
      );
    }
  }

  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}

class _Stone {
  final double x;
  final double w;
  final double shade;
  const _Stone({required this.x, required this.w, required this.shade});
}
