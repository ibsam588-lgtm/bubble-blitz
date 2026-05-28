import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/player_data.dart';
import '../../utils/constants.dart';
import '../bubble_blitz_game.dart';

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
      : super(
            position: position, size: Vector2(_w, _h), anchor: Anchor.topLeft);

  Color get _bodyColor {
    switch (character) {
      case CharacterType.dragon:
        return AppConstants.heroGreen;
      case CharacterType.phoenix:
        return AppConstants.fireRed;
      case CharacterType.shadow:
        return AppConstants.bubbleBlue;
    }
  }

  Color get _accentColor {
    switch (character) {
      case CharacterType.dragon:
        return AppConstants.accentYellow;
      case CharacterType.phoenix:
        return AppConstants.foamWhite;
      case CharacterType.shadow:
        return AppConstants.accentYellow;
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
    if (invincible && (invincibleTimer * 12).floor().isOdd) {
      return;
    }

    canvas.save();
    if (!facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final body = Paint()..color = _bodyColor;
    final bodyShade = Paint()
      ..color = Color.lerp(_bodyColor, AppConstants.uiDark, 0.32)!;
    final accent = Paint()..color = _accentColor;
    final belly = Paint()..color = const Color(0xFFFFF5C6);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF071015);

    canvas.drawOval(
      Rect.fromLTWH(5, size.y - 4, size.x - 6, 5),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final tail = Path()
      ..moveTo(8, 28)
      ..quadraticBezierTo(-4, 24, 5, 15)
      ..quadraticBezierTo(12, 21, 15, 29)
      ..close();
    canvas.drawPath(tail, bodyShade);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 16, 22, 22),
        const Radius.circular(12),
      ),
      body,
    );
    canvas.drawOval(const Rect.fromLTWH(13, 22, 11, 13), belly);

    canvas.drawOval(const Rect.fromLTWH(9, 6, 23, 20), body);
    canvas.drawOval(const Rect.fromLTWH(24, 13, 12, 8), body);
    canvas.drawOval(const Rect.fromLTWH(23, 15, 11, 6), belly);

    canvas.drawOval(const Rect.fromLTWH(8, 34, 9, 5), bodyShade);
    canvas.drawOval(const Rect.fromLTWH(22, 34, 9, 5), bodyShade);
    canvas.drawCircle(const Offset(6, 25), 4.6, accent);
    canvas.drawCircle(const Offset(29.5, 25), 4.6, accent);

    final crest = Path()
      ..moveTo(11, 8)
      ..lineTo(14, 1)
      ..lineTo(17, 8)
      ..lineTo(20, 1)
      ..lineTo(23, 8);
    canvas.drawPath(
      crest,
      Paint()
        ..color = accent.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawOval(const Rect.fromLTWH(12, 8, 8, 11), white);
    canvas.drawOval(const Rect.fromLTWH(21, 8, 8, 11), white);
    canvas.drawCircle(const Offset(16, 13), 2.8, ink);
    canvas.drawCircle(const Offset(25, 13), 2.8, ink);
    canvas.drawCircle(const Offset(17.2, 11.7), 1, white);
    canvas.drawCircle(const Offset(26.2, 11.7), 1, white);

    if (character == CharacterType.phoenix) {
      final mark = Paint()
        ..color = AppConstants.foamWhite.withValues(alpha: 0.84)
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(12, 18), const Offset(22, 23), mark);
      canvas.drawLine(const Offset(15, 7), const Offset(27, 10), mark);
    }

    canvas.drawArc(
      const Rect.fromLTWH(18, 17, 8, 5),
      0.05,
      3.0,
      false,
      Paint()
        ..color = ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawCircle(
      const Offset(34, 18),
      6,
      Paint()
        ..color = AppConstants.bubbleBlue.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    canvas.restore();
  }
}
