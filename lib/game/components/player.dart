import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../models/player_data.dart';
import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';
import 'platform.dart';

class Player extends PositionComponent with HasGameReference<BubbleBlitzGame> {
  double vx = 0;
  double vy = 0;
  bool onGround = false;
  bool facingRight = true;
  double shootCooldown = 0;
  bool invincible = false;
  double invincibleTimer = 0;
  CharacterType character = CharacterType.dragon;

  static const double _w = 36;
  static const double _h = 40;

  Player({required Vector2 position, required this.character})
      : super(position: position, size: Vector2(_w, _h), anchor: Anchor.topLeft);

  Color get _bodyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF4CAF50);
      case CharacterType.phoenix: return const Color(0xFFFF5722);
      case CharacterType.shadow:  return const Color(0xFF4527A0);
    }
  }

  Color get _bellyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF81C784);
      case CharacterType.phoenix: return const Color(0xFFFFCC02);
      case CharacterType.shadow:  return const Color(0xFF9575CD);
    }
  }

  Color get _outlineColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF1B5E20);
      case CharacterType.phoenix: return const Color(0xFFBF360C);
      case CharacterType.shadow:  return const Color(0xFF1A237E);
    }
  }

  // ── Physics ──────────────────────────────────────────────────────────────

  void moveLeft()  { vx = -AppConstants.playerSpeed; facingRight = false; }
  void moveRight() { vx =  AppConstants.playerSpeed; facingRight = true;  }
  void stopMoving() { vx = 0; }

  void jump() {
    if (onGround) { vy = AppConstants.playerJumpVelocity; onGround = false; }
  }

  void shoot() {
    if (shootCooldown > 0) return;
    shootCooldown = 0.35;
    game.spawnPlayerBubble(this);
  }

  void hit() {
    if (invincible) return;
    invincible = true;
    invincibleTimer = 1.4;
    add(OpacityEffect.fadeOut(EffectController(duration: 0.15, alternate: true, repeatCount: 4)));
    game.onPlayerHit();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (shootCooldown > 0) shootCooldown -= dt;
    if (invincible) {
      invincibleTimer -= dt;
      if (invincibleTimer <= 0) invincible = false;
    }

    vy += AppConstants.gravity * dt;
    if (vy > 700) vy = 700;

    position.x += vx * dt;
    _resolveHorizontal();

    position.y += vy * dt;
    onGround = false;
    _resolveVertical();

    if (position.x < 0) position.x = 0;
    if (position.x + size.x > game.worldSize.x) position.x = game.worldSize.x - size.x;

    if (position.y > game.worldSize.y + 40) {
      position = Vector2(60, game.worldSize.y - 120);
      vy = 0;
      hit();
    }
  }

  void _resolveHorizontal() {
    final myRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    for (final p in game.platforms) {
      if (myRect.overlaps(p.rect)) {
        if (vx > 0) position.x = p.rect.left - size.x;
        else if (vx < 0) position.x = p.rect.right;
      }
    }
  }

  void _resolveVertical() {
    final myRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    for (final p in game.platforms) {
      if (myRect.overlaps(p.rect)) {
        if (vy > 0) { position.y = p.rect.top - size.y; vy = 0; onGround = true; }
        else if (vy < 0) { position.y = p.rect.bottom; vy = 0; }
      }
    }
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2; // 18

    // Wing nub (drawn behind body, on the back side)
    final wingX = facingRight ? cx - 13.0 : cx + 13.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(wingX, 17), width: 17, height: 12),
      Paint()..color = _bodyColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(wingX, 17), width: 17, height: 12),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Main chubby oval body
    canvas.drawOval(
      Rect.fromLTWH(2, 5, 32, 32),
      Paint()..color = _bodyColor,
    );
    canvas.drawOval(
      Rect.fromLTWH(2, 5, 32, 32),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Lighter belly
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 25), width: 19, height: 21),
      Paint()..color = _bellyColor,
    );

    // Horn on top of head (front side)
    final hornCx = facingRight ? cx + 5.0 : cx - 5.0;
    final hornPath = Path()
      ..moveTo(hornCx - 4, 8)
      ..lineTo(hornCx, 0)
      ..lineTo(hornCx + 4, 8)
      ..close();
    canvas.drawPath(hornPath, Paint()..color = _outlineColor);
    canvas.drawPath(
      hornPath,
      Paint()
        ..color = _bellyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Large white eye sclera
    final eyeX = facingRight ? cx + 7.0 : cx - 7.0;
    canvas.drawCircle(Offset(eyeX, 15), 6.5, Paint()..color = Colors.white);
    // Eye outline
    canvas.drawCircle(
      Offset(eyeX, 15),
      6.5,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Black pupil
    final pupilX = facingRight ? eyeX + 2.0 : eyeX - 2.0;
    canvas.drawCircle(Offset(pupilX, 15.5), 3.8, Paint()..color = Colors.black);
    // Shine dot
    canvas.drawCircle(Offset(eyeX + (facingRight ? -1.0 : 1.0), 11.5), 1.5,
        Paint()..color = Colors.white);

    // Stubby legs at bottom
    final legPaint = Paint()..color = _outlineColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 14, 35, 12, 5), const Radius.circular(3)),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2, 35, 12, 5), const Radius.circular(3)),
      legPaint,
    );

    // Open mouth when shooting
    if (shootCooldown > 0.1) {
      final mouthX = facingRight ? eyeX + 9.0 : eyeX - 9.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mouthX, 21), width: 9, height: 6),
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(mouthX, 19.5), width: 7, height: 2),
        Paint()..color = Colors.white,
      );
    }
  }
}
