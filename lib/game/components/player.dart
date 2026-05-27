import 'dart:math' as math;

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
      case CharacterType.dragon:
        return AppConstants.bubbleBlue;
      case CharacterType.phoenix:
        return AppConstants.bubbleOrange;
      case CharacterType.shadow:
        return AppConstants.bubblePurple;
    }
  }

  void moveLeft() {
    vx = -AppConstants.playerSpeed;
    facingRight = false;
  }

  void moveRight() {
    vx = AppConstants.playerSpeed;
    facingRight = true;
  }

  void stopMoving() {
    vx = 0;
  }

  void jump() {
    if (onGround) {
      vy = AppConstants.playerJumpVelocity;
      onGround = false;
    }
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

    // Apply gravity
    vy += AppConstants.gravity * dt;
    if (vy > 700) vy = 700;

    // Move horizontally with collision
    position.x += vx * dt;
    _resolveHorizontal();

    // Move vertically with collision
    position.y += vy * dt;
    onGround = false;
    _resolveVertical();

    // Bounds
    if (position.x < 0) position.x = 0;
    if (position.x + size.x > game.worldSize.x) {
      position.x = game.worldSize.x - size.x;
    }

    // Fall off bottom = damage
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
        if (vx > 0) {
          position.x = p.rect.left - size.x;
        } else if (vx < 0) {
          position.x = p.rect.right;
        }
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

  @override
  void render(Canvas canvas) {
    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(10),
    );
    canvas.drawRRect(bodyRect, Paint()..color = _bodyColor);

    // Belly accent
    final bellyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(6, 18, size.x - 12, size.y - 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(bellyRect, Paint()..color = Colors.white.withValues(alpha: 0.7));

    // Eyes
    final eyeY = 10.0;
    final eyeOffsetL = facingRight ? 8.0 : 16.0;
    final eyeOffsetR = facingRight ? 22.0 : 28.0;
    canvas.drawCircle(Offset(eyeOffsetL, eyeY), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(eyeOffsetR, eyeY), 4, Paint()..color = Colors.white);
    final pupilDx = facingRight ? 1.5 : -1.5;
    canvas.drawCircle(Offset(eyeOffsetL + pupilDx, eyeY), 2, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(eyeOffsetR + pupilDx, eyeY), 2, Paint()..color = Colors.black);

    // Spikes on back
    final spikePaint = Paint()..color = _bodyColor.withValues(alpha: 0.85);
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final cx = facingRight ? 4.0 + (i * 4) : size.x - 4 - (i * 4);
      path.moveTo(cx, 4);
      path.lineTo(cx - 3, 0);
      path.lineTo(cx + 3, 0);
      path.close();
      canvas.drawPath(path, spikePaint);
    }
  }

  double _wobble(double dt) {
    return math.sin(dt * 6) * 0.04;
  }
}
