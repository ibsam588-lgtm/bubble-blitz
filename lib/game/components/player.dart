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

  static const double _w = 38;
  static const double _h = 38;

  Player({required Vector2 position, required this.character})
      : super(position: position, size: Vector2(_w, _h), anchor: Anchor.topLeft);

  // ── BB2 Bub / Bob palette ──────────────────────────────────────────────────

  Color get _bodyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF2EC05C); // Bub: emerald green
      case CharacterType.phoenix: return const Color(0xFF00B8D9); // Bob: cyan-blue
      case CharacterType.shadow:  return const Color(0xFFE91E8C); // pink-magenta
    }
  }

  Color get _bellyColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFFA8E6C3);
      case CharacterType.phoenix: return const Color(0xFFB2EBF2);
      case CharacterType.shadow:  return const Color(0xFFF8BBD9);
    }
  }

  Color get _outlineColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF0A4020);
      case CharacterType.phoenix: return const Color(0xFF00405A);
      case CharacterType.shadow:  return const Color(0xFF5A0030);
    }
  }

  Color get _hornColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF14602E);
      case CharacterType.phoenix: return const Color(0xFF006080);
      case CharacterType.shadow:  return const Color(0xFF7B0040);
    }
  }

  Color get _irisColor {
    switch (character) {
      case CharacterType.dragon:  return const Color(0xFF00D4A0);
      case CharacterType.phoenix: return const Color(0xFF00D0F0);
      case CharacterType.shadow:  return const Color(0xFFFF70CC);
    }
  }

  // ── Physics ───────────────────────────────────────────────────────────────

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
    add(OpacityEffect.fadeOut(EffectController(
        duration: 0.15, alternate: true, repeatCount: 4)));
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
    if (position.x + size.x > game.worldSize.x) {
      position.x = game.worldSize.x - size.x;
    }

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
        if (vy > 0) {
          position.y = p.rect.top - size.y;
          vy = 0;
          onGround = true;
        } else if (vy < 0) {
          position.y = p.rect.bottom;
          vy = 0;
        }
      }
    }
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2; // 19
    final cy = size.y / 2; // 19

    const bodyR = 15.0;
    final bodyCenter = Offset(cx, cy + 1);

    // ── Back arm nub (behind body) ──
    final backArmX = facingRight ? cx - 14.0 : cx + 14.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(backArmX, cy + 5), width: 9, height: 7),
      Paint()..color = _bodyColor,
    );

    // ── Main round body ──
    canvas.drawCircle(bodyCenter, bodyR, Paint()..color = _bodyColor);
    canvas.drawCircle(
      bodyCenter,
      bodyR,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // ── Oval belly ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 16, height: 13),
      Paint()..color = _bellyColor,
    );

    // ── Small curved horn (front-top) ──
    final hornPivotX = facingRight ? cx + 4.0 : cx - 4.0;
    final hornPath = Path()
      ..moveTo(hornPivotX - 3, cy - 11)
      ..quadraticBezierTo(
          hornPivotX + 6, cy - 22, hornPivotX + 8, cy - 13)
      ..lineTo(hornPivotX + 2, cy - 11)
      ..close();
    canvas.drawPath(hornPath, Paint()..color = _hornColor);
    canvas.drawPath(
      hornPath,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── HUGE round eye — BB2's signature feature (~40% of face) ──
    final eyeX = facingRight ? cx + 4.5 : cx - 4.5;
    const eyeY = -1.0; // offset from cy
    const eyeR = 9.0; // large!
    final eyeCenter = Offset(eyeX, cy + eyeY);

    // White sclera
    canvas.drawCircle(eyeCenter, eyeR, Paint()..color = Colors.white);
    // Eye border
    canvas.drawCircle(
      eyeCenter,
      eyeR,
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    // Colored iris
    final irisOff = facingRight ? const Offset(1.5, 1.0) : const Offset(-1.5, 1.0);
    canvas.drawCircle(
      eyeCenter + irisOff, 5.8, Paint()..color = _irisColor);
    // Black pupil
    final pupilOff =
        facingRight ? const Offset(2.0, 1.5) : const Offset(-2.0, 1.5);
    canvas.drawCircle(
      eyeCenter + pupilOff, 3.4, Paint()..color = Colors.black);
    // Primary shine
    final shineOff =
        facingRight ? const Offset(-2.5, -3.5) : const Offset(2.5, -3.5);
    canvas.drawCircle(
      eyeCenter + shineOff, 2.2, Paint()..color = Colors.white);
    // Tiny secondary shine
    final shine2Off =
        facingRight ? const Offset(3.0, 3.5) : const Offset(-3.0, 3.5);
    canvas.drawCircle(
      eyeCenter + shine2Off, 1.0,
      Paint()..color = Colors.white.withValues(alpha: 0.7));

    // ── Front arm nub (in front of body) ──
    final frontArmX = facingRight ? cx + 14.5 : cx - 14.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(frontArmX, cy + 5), width: 10, height: 8),
      Paint()..color = _bodyColor,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(frontArmX, cy + 5), width: 10, height: 8),
      Paint()
        ..color = _outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── Open mouth when shooting ──
    if (shootCooldown > 0.1) {
      final mouthX = facingRight ? cx + 12.0 : cx - 12.0;
      final mouthY = cy + 7.0;
      // Mouth opening (red)
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mouthX, mouthY), width: 12, height: 10),
        Paint()..color = const Color(0xFFE53935),
      );
      // Teeth
      canvas.drawRect(
        Rect.fromCenter(center: Offset(mouthX, mouthY - 3), width: 10, height: 3),
        Paint()..color = Colors.white,
      );
      // Tongue
      canvas.drawOval(
        Rect.fromCenter(center: Offset(mouthX, mouthY + 2), width: 7, height: 4),
        Paint()..color = const Color(0xFFFF7043),
      );
    }
  }
}
