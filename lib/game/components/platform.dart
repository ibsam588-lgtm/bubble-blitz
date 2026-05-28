import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../world/level_data.dart';

class GamePlatform extends PositionComponent {
  final PlatformSpec spec;
  final Color color;
  final int world;
  double _t = 0;
  late final double _startX;
  late final List<Offset> _stonePatches;

  GamePlatform({required this.spec, required this.color, required this.world})
      : super(
          position: Vector2(spec.x, spec.y),
          size: Vector2(spec.width, spec.height),
        ) {
    _startX = spec.x;
    _stonePatches = _buildStonePatches();
  }

  List<Offset> _buildStonePatches() {
    final rand = math.Random((spec.x * 7 + spec.y * 13).toInt().abs());
    final count = (spec.width / 20).floor() + 1;
    return List.generate(count, (_) => Offset(
      rand.nextDouble() * (spec.width - 10) + 5,
      rand.nextDouble() * (spec.height - 4) + 2,
    ));
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
    switch (world) {
      case 1: _renderBamboo(canvas); break;
      case 2: _renderWood(canvas);   break;
      case 3: _renderStone(canvas);  break;
      default: _renderDefault(canvas);
    }
  }

  // ── World 1: Bamboo ───────────────────────────────────────────────────────

  void _renderBamboo(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(6));

    // Bamboo stalk body
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF558B2F));

    // Inner lighter stripe (depth)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 2, w * 0.5, h - 4), const Radius.circular(3)),
      Paint()..color = const Color(0xFF689F38).withValues(alpha: 0.5),
    );

    // Node joint rings every 16 px
    final nodePaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    for (double nx = 16; nx < w; nx += 16) {
      canvas.drawLine(Offset(nx, 0), Offset(nx, h), nodePaint);
    }

    // Bright grass-green cap on top surface
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, 5), const Radius.circular(4)),
      Paint()..color = const Color(0xFF76FF03),
    );

    // Moving platform shimmer
    if (spec.moving) {
      final s = ((math.sin(_t * 4) + 1) / 2) * 0.18;
      canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: s));
    }
  }

  // ── World 2: Wood planks ──────────────────────────────────────────────────

  void _renderWood(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(6));

    // Wood base
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF6D4C41));

    // Wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (double gy = 5; gy < h - 1; gy += 4) {
      canvas.drawLine(Offset(3, gy), Offset(w - 3, gy), grainPaint);
    }

    // Mossy green top edge
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, 5), const Radius.circular(4)),
      Paint()..color = const Color(0xFF4CAF50),
    );
    // Small moss bumps
    final bumpPaint = Paint()..color = const Color(0xFF388E3C);
    for (double bx = 8; bx < w - 4; bx += 13) {
      canvas.drawOval(Rect.fromCenter(center: Offset(bx, 2), width: 9, height: 5), bumpPaint);
    }

    // Dark outline
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF3E2723)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (spec.moving) {
      final s = ((math.sin(_t * 4) + 1) / 2) * 0.18;
      canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: s));
    }
  }

  // ── World 3: Stone / rock slab ────────────────────────────────────────────

  void _renderStone(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h), const Radius.circular(6));

    // Stone base
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF455A64));

    // Lighter stone patches for texture
    for (final p in _stonePatches) {
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 11, height: 5),
        Paint()..color = const Color(0xFF546E7A).withValues(alpha: 0.65),
      );
    }

    // Crack line
    if (w > 36) {
      final crackX = w * 0.42;
      final crackPaint = Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(crackX, 2), Offset(crackX + 7, h - 2), crackPaint);
    }

    // Lava glow gradient on bottom edge
    final glowShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, const Color(0xFFFF6F00).withValues(alpha: 0.55)],
    ).createShader(Rect.fromLTWH(0, h - 7, w, 7));
    canvas.drawRect(Rect.fromLTWH(0, h - 7, w, 7), Paint()..shader = glowShader);

    // Dark outline
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF1C313A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (spec.moving) {
      final s = ((math.sin(_t * 4) + 1) / 2) * 0.14;
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFF6F00).withValues(alpha: s));
    }
  }

  // ── Fallback ──────────────────────────────────────────────────────────────

  void _renderDefault(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, size.x - 4, 4), const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  Rect get rect => Rect.fromLTWH(position.x, position.y, size.x, size.y);
}
