import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/player_data.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';
import '../utils/assets.dart';
import 'components/bubble.dart';
import 'components/coin.dart';
import 'components/enemy.dart';
import 'components/enemy_types.dart';
import 'components/hud.dart';
import 'components/platform.dart';
import 'components/player.dart';
import 'components/powerup.dart';
import 'managers/game_manager.dart';
import 'world/level.dart';
import 'world/level_data.dart';

class BubbleBlitzGame extends FlameGame with KeyboardEvents, TapDetector {
  final int initialLevel;
  final GameManager manager;
  final void Function(GameManager) onGameOver;
  final void Function(GameManager) onLevelComplete;

  BubbleBlitzGame({
    required this.initialLevel,
    required this.manager,
    required this.onGameOver,
    required this.onLevelComplete,
  });

  Player? player;
  final List<GamePlatform> platforms = [];
  final List<Enemy> enemies = [];
  final List<Bubble> bubbles = [];
  final List<Coin> coins = [];
  final List<Powerup> powerups = [];

  late Vector2 worldSize;
  late LevelSpec currentSpec;
  bool _ended = false;
  double _bgT = 0;

  // Touch controls state
  int touchMove = 0;
  bool touchJump = false;
  bool touchShoot = false;

  @override
  Future<void> onLoad() async {
    worldSize = Vector2(LevelData.worldW, LevelData.worldH);

    // Scale the fixed 480x800 design to fit ANY screen. All gameplay now lives
    // inside `world`, so the camera zoom actually applies to it (previously the
    // content was in the game root and rendered tiny in a corner — the old
    // "blank levels" bug). Anchor top-left so world (0,0) maps to screen (0,0).
    camera.viewfinder.visibleGameSize = worldSize;
    camera.viewfinder.anchor = Anchor.topLeft;

    // Build the level first so currentSpec is initialized before the
    // background layer (which reads it) ever renders. Priority keeps the
    // background behind gameplay and the border/HUD in front.
    await _loadLevel(initialLevel);
    world.add(_BackgroundLayer());
    world.add(GameHud());
    world.add(_BorderLayer());
  }

  Future<void> _loadLevel(int level) async {
    _ended = false;
    currentSpec = LevelData.byLevel(level);
    manager.reset(level);

    world.children.whereType<GamePlatform>().forEach(world.remove);
    world.children.whereType<Enemy>().forEach(world.remove);
    world.children.whereType<Bubble>().forEach(world.remove);
    world.children.whereType<Coin>().forEach(world.remove);
    world.children.whereType<Powerup>().forEach(world.remove);
    world.children.whereType<Player>().forEach(world.remove);
    world.children.whereType<EnemyProjectile>().forEach(world.remove);
    platforms.clear();
    enemies.clear();
    bubbles.clear();
    coins.clear();
    powerups.clear();

    final levelObj = Level(currentSpec);
    for (final c in levelObj.build()) {
      world.add(c);
      if (c is GamePlatform) platforms.add(c);
      if (c is Enemy) enemies.add(c);
      if (c is Coin) coins.add(c);
      if (c is Powerup) powerups.add(c);
    }

    final charId = SaveService.instance.data.selectedChar;
    final char = CharacterType.values.firstWhere(
      (c) => c.id == charId, orElse: () => CharacterType.dragon);
    final p = Player(
      position: Vector2(currentSpec.playerSpawn.dx, currentSpec.playerSpawn.dy),
      character: char,
    );
    world.add(p);
    player = p;
    AudioService.instance.playBgm();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bgT += dt;
    if (_ended) return;
    manager.tickPowerups(dt);

    final p = player;
    if (p == null) return;

    // Movement: touch has priority; fall back to held keyboard keys;
    // always call stopMoving() when no input so vx doesn't persist.
    if (touchMove < 0) {
      p.moveLeft();
    } else if (touchMove > 0) {
      p.moveRight();
    } else {
      final kLeft  = _pressed.contains(LogicalKeyboardKey.arrowLeft)  ||
                     _pressed.contains(LogicalKeyboardKey.keyA);
      final kRight = _pressed.contains(LogicalKeyboardKey.arrowRight) ||
                     _pressed.contains(LogicalKeyboardKey.keyD);
      if (kLeft && !kRight)       p.moveLeft();
      else if (kRight && !kLeft)  p.moveRight();
      else                        p.stopMoving(); // no input → stop sliding
    }

    if (touchJump)  { p.jump();  touchJump  = false; }
    if (touchShoot) { p.shoot(); touchShoot = false; }

    for (final e in enemies.toList()) {
      if (e.parent == null) continue;
      if (e.checkPlayerCollision(p)) p.hit();
    }

    bubbles.removeWhere((b) => b.parent == null);
    enemies.removeWhere((e) => e.parent == null);
    coins.removeWhere((c) => c.parent == null);
    powerups.removeWhere((p) => p.parent == null);

    if (!manager.isLevelComplete && enemies.isEmpty) {
      manager.completeLevel();
      _ended = true;
      AudioService.instance.playSfx(Assets.flameLevelComplete);
      _finishLevel();
    }

    if (manager.isGameOver && !_ended) {
      _ended = true;
      AudioService.instance.playSfx(Assets.flameGameOver);
      pauseEngine();
      onGameOver(manager);
    }
  }

  Future<void> _finishLevel() async {
    final stars = manager.starsEarned();
    await SaveService.instance.setLevelStars(manager.currentLevel, stars);
    await SaveService.instance.unlockLevel(manager.currentLevel + 1);
    await SaveService.instance.saveHighScore(manager.score);
    await SaveService.instance.addCoins(manager.coinsCollected);
    pauseEngine();
    onLevelComplete(manager);
  }

  void spawnPlayerBubble(Player p) {
    final dir = p.facingRight ? 1.0 : -1.0;
    final useMulti = manager.multiBubbleShots > 0;
    final big = manager.bigBubbleActive;
    AudioService.instance.playSfx(Assets.flameBubbleShoot);

    if (useMulti) {
      manager.useMultiBubble();
      for (int i = -1; i <= 1; i++) {
        final b = Bubble(
          position: p.position + Vector2(p.size.x / 2, p.size.y / 2),
          vx: dir * 240, vy: i * 60.0, isBig: big,
        );
        world.add(b); bubbles.add(b);
      }
    } else {
      final b = Bubble(
        position: p.position + Vector2(p.size.x / 2, p.size.y / 2),
        vx: dir * 280, isBig: big,
      );
      world.add(b); bubbles.add(b);
    }
  }

  void spawnEnemyProjectile(Enemy from) {
    final p = player;
    if (p == null) return;
    final dx = p.position.x - from.position.x;
    final proj = EnemyProjectile(
      position: from.position + from.size / 2,
      vx: dx.sign * 150, vy: -50,
    );
    world.add(proj);
  }

  void spawnMinion(Enemy boss) {
    final slime = SlimeEnemy(
        position: Vector2(boss.position.x + 20, boss.position.y + boss.size.y));
    world.add(slime); enemies.add(slime);
  }

  void spawnPopEffect(Vector2 at) {
    AudioService.instance.playSfx(Assets.flameBubblePop);
    world.add(PopBurst(position: at.clone(), color: const Color(0xFF80E5FF)));
  }

  void onEnemyDefeated(Enemy e) {
    manager.addScore(e.scoreValue);
    AudioService.instance.playSfx(Assets.flameBubblePop);
    final center = e.position + e.size / 2;
    world.add(PopBurst(position: center, color: const Color(0xFFFFEB3B)));
    final c = Coin(position: e.position.clone());
    world.add(c); coins.add(c);
  }

  void onCoinCollected(Coin c) {
    manager.addCoin();
    AudioService.instance.playSfx(Assets.flameCoinCollect);
    world.add(PopBurst(
        position: c.position + c.size / 2, color: const Color(0xFFFFD740)));
  }

  void onPowerupCollected(Powerup p) {
    if (p.kind == 'multi') manager.multiBubbleShots += 3;
    else if (p.kind == 'big') manager.activateBigBubble();
    AudioService.instance.playSfx(Assets.flameCoinCollect);
  }

  void onPlayerHit() {
    AudioService.instance.playSfx(Assets.flamePlayerHit);
    manager.loseLife();
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    // The world is uniformly scaled by the camera zoom (anchored top-left), so
    // divide the screen tap by the zoom to recover world coordinates.
    final zoom = camera.viewfinder.zoom;
    final pos = info.eventPosition.global / (zoom == 0 ? 1.0 : zoom);
    for (final b in bubbles.toList()) {
      if (b.trappedEnemy != null) {
        final d = (b.position - pos).length;
        if (d < b.radius + 16) { b.popByPlayer(); return; }
      }
    }
  }

  final Set<LogicalKeyboardKey> _pressed = {};

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Keep the held-key set up to date — movement is handled in update()
    // so it fires correctly every frame (not just on key events).
    _pressed..clear()..addAll(keysPressed);
    final p = player;
    if (p == null) return KeyEventResult.ignored;

    // One-shot actions: jump and shoot trigger on key-down only.
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        p.jump();
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ ||
          event.logicalKey == LogicalKeyboardKey.keyZ ||
          event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        p.shoot();
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => Colors.black;

  // ── Background rendering (drawn by _BackgroundLayer inside the world) ─────

  /// Dark cave/dungeon background — BB2 authentic style.
  /// Stone walls on left/right, dark gradient sky, atmospheric drips/particles.
  void _renderCaveBg(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // ── Background gradient (deep cave dark) ──────────────────────────────
    final bgColors = _caveBgColors();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect),
    );

    // ── Stone wall tiles — left side ──────────────────────────────────────
    _drawStoneWall(canvas, 0, 0, 28, h);

    // ── Stone wall tiles — right side ─────────────────────────────────────
    _drawStoneWall(canvas, w - 28, 0, 28, h);

    // ── Stone ceiling tiles ───────────────────────────────────────────────
    _drawCeilingStones(canvas, w, 22);

    // ── Stalactites hanging from ceiling ─────────────────────────────────
    final stalRand = math.Random(42);
    for (int i = 0; i < 10; i++) {
      final sx = 32 + stalRand.nextDouble() * (w - 64);
      final sLen = 14 + stalRand.nextDouble() * 28;
      _drawStalactite(canvas, sx, 22, sLen);
    }

    // ── World-specific atmospheric effects ───────────────────────────────
    switch (currentSpec.world) {
      case 1: _drawCaveWaterfall(canvas, w, h); break;
      case 2: _drawCaveFireflies(canvas, w, h); break;
      case 3: _drawCaveLavaGlow(canvas, w, h); break;
    }

    // ── Dripping water from ceiling (all worlds) ─────────────────────────
    _drawCaveDrips(canvas, w, h);

    // ── Floor stone strip ────────────────────────────────────────────────
    _drawStoneWall(canvas, 0, h - 24, w, 24);
  }

  List<Color> _caveBgColors() {
    switch (currentSpec.world) {
      case 1: return const [Color(0xFF0A1A28), Color(0xFF0D2230), Color(0xFF0A2A18)];
      case 2: return const [Color(0xFF0D0A1A), Color(0xFF1A0D2A), Color(0xFF0A0D20)];
      case 3: return const [Color(0xFF1A0800), Color(0xFF2A0D00), Color(0xFF1A0A00)];
      default: return const [Color(0xFF0A1020), Color(0xFF0D1830), Color(0xFF0A1020)];
    }
  }

  void _drawStoneWall(Canvas canvas, double x, double y, double w, double h) {
    const tileW = 28.0;
    const tileH = 22.0;
    for (double ty = y; ty < y + h; ty += tileH) {
      final row = ((ty - y) / tileH).floor();
      final xOff = (row % 2 == 0) ? 0.0 : tileW / 2;
      for (double tx = x - xOff; tx < x + w; tx += tileW) {
        if (tx + tileW < x || tx > x + w) continue;
        // Clip to wall area
        final bx = tx.clamp(x, x + w - 1);
        final bw = (tx + tileW).clamp(x, x + w) - bx;
        if (bw <= 0) continue;

        // Stone block base
        final shade = 0.50 + ((tx * 7 + ty * 13).toInt().abs() % 20) / 100.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bx + 1, ty + 1, bw - 2, tileH - 2),
              const Radius.circular(2)),
          Paint()
            ..color = Color.fromARGB(255, (80 * shade).toInt(),
                (90 * shade).toInt(), (100 * shade).toInt()),
        );
        // Top highlight
        canvas.drawLine(
          Offset(bx + 2, ty + 2),
          Offset(bx + bw - 2, ty + 2),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.10)
            ..strokeWidth = 1.0,
        );
        // Mortar joint outline
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bx, ty, bw, tileH), const Radius.circular(2)),
          Paint()
            ..color = const Color(0xFF060E14)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawCeilingStones(Canvas canvas, double w, double h) {
    // Solid dark ceiling bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF060E14),
    );
    // Stone texture on bottom edge
    _drawStoneWall(canvas, 0, h - 8, w, 8);
  }

  void _drawStalactite(Canvas canvas, double x, double ceilY, double len) {
    // Rock-colored triangle icicle
    final path = Path()
      ..moveTo(x - 5, ceilY)
      ..lineTo(x + 5, ceilY)
      ..lineTo(x, ceilY + len)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF2A3A44),
    );
    // Lighter highlight
    canvas.drawPath(
      Path()
        ..moveTo(x - 3, ceilY)
        ..lineTo(x - 1, ceilY)
        ..lineTo(x, ceilY + len * 0.6)
        ..lineTo(x - 2, ceilY + len * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    // Water drop tip
    canvas.drawCircle(
      Offset(x, ceilY + len),
      2.2,
      Paint()..color = const Color(0xFF90CAF9).withValues(alpha: 0.6),
    );
  }

  void _drawCaveDrips(Canvas canvas, double w, double h) {
    final rand = math.Random(31);
    for (int i = 0; i < 14; i++) {
      final dx = 32 + rand.nextDouble() * (w - 64);
      final speed = 60 + rand.nextDouble() * 80;
      final phase = rand.nextDouble() * math.pi * 2;
      // Drip travels from ceiling down
      final dy = ((_bgT * speed + phase * 20) % (h - 40)) + 22;
      final alpha = 1.0 - (dy / h);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, dy), width: 3, height: 6),
        Paint()
          ..color =
              const Color(0xFF90CAF9).withValues(alpha: alpha * 0.45),
      );
    }
  }

  void _drawCaveWaterfall(Canvas canvas, double w, double h) {
    // Right-side waterfall in world 1
    final wfX = w - 40.0;
    final scroll = (_bgT * 80) % h;
    final wfPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.25)
      ..strokeWidth = 6;
    canvas.drawLine(Offset(wfX, 22), Offset(wfX - 4, h - 24), wfPaint);
    // Ripple shimmer
    for (double ry = scroll; ry < h; ry += 20) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(wfX - 2, ry), width: 10, height: 4),
        Paint()..color = Colors.white.withValues(alpha: 0.12),
      );
    }
  }

  void _drawCaveFireflies(Canvas canvas, double w, double h) {
    final rand = math.Random(88);
    for (int i = 0; i < 18; i++) {
      final fx = 32 + rand.nextDouble() * (w - 64);
      final fy = 40 + rand.nextDouble() * (h * 0.8);
      final blink = (math.sin(_bgT * 2.2 + i * 1.7) + 1) / 2;
      canvas.drawCircle(
        Offset(fx, fy),
        2.5,
        Paint()
          ..color = const Color(0xFFCEFF1A).withValues(alpha: blink * 0.75),
      );
    }
  }

  void _drawCaveLavaGlow(Canvas canvas, double w, double h) {
    final pulse = (math.sin(_bgT * 2.2) + 1) / 2;
    // Bottom lava glow
    canvas.drawRect(
      Rect.fromLTWH(0, h - 80, w, 80),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFF6D00).withValues(alpha: 0.35 + pulse * 0.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, h - 80, w, 80)),
    );
    // Floating embers
    final eRand = math.Random(77);
    for (int i = 0; i < 14; i++) {
      final ex = 32 + eRand.nextDouble() * (w - 64);
      final speed = 40 + eRand.nextDouble() * 60;
      final ey = (h - (_bgT * speed * 0.5 + i * 50) % h).clamp(0.0, h);
      final g = (math.sin(_bgT * 3 + i) + 1) / 2;
      canvas.drawCircle(
        Offset(ex + math.sin(_bgT * 1.5 + i) * 8, ey),
        1.5 + g * 1.5,
        Paint()
          ..color = const Color(0xFFFF9800).withValues(alpha: 0.45 + g * 0.4),
      );
    }
  }

  /// Diamond-chain border frame around the play area — classic BB2 style.
  void _renderDiamondBorderFrame(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;

    // Border color cycling per world
    final Color chainColor;
    switch (currentSpec.world) {
      case 1: chainColor = const Color(0xFF00E676); break;  // green
      case 2: chainColor = const Color(0xFF7C4DFF); break;  // purple
      case 3: chainColor = const Color(0xFFFF6D00); break;  // orange
      default: chainColor = const Color(0xFF00B0FF); break;
    }
    final Color chainGlow = chainColor.withValues(alpha: 0.35);
    final Color chainDark = const Color(0xFF172830);

    // Frame width
    const fw = 26.0;
    // Diamond chain spacing
    const ds = 18.0;

    // Draw a chain of diamonds along each edge
    void drawChain(List<Offset> centers) {
      for (int i = 0; i < centers.length; i++) {
        final c = centers[i];
        // Link connector to next
        if (i < centers.length - 1) {
          canvas.drawLine(c, centers[i + 1],
              Paint()
                ..color = chainDark
                ..strokeWidth = 4);
          canvas.drawLine(c, centers[i + 1],
              Paint()
                ..color = chainColor.withValues(alpha: 0.5)
                ..strokeWidth = 2);
        }
        // Glow halo
        canvas.drawCircle(c, 7, Paint()..color = chainGlow);
        // Diamond shape
        final dp = Path()
          ..moveTo(c.dx, c.dy - 7)
          ..lineTo(c.dx + 5, c.dy)
          ..lineTo(c.dx, c.dy + 7)
          ..lineTo(c.dx - 5, c.dy)
          ..close();
        canvas.drawPath(dp, Paint()..color = chainDark);
        canvas.drawPath(dp, Paint()..color = chainColor);
        canvas.drawPath(dp,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8);
        // Inner highlight dot
        canvas.drawCircle(c + const Offset(-1.5, -2), 1.5,
            Paint()..color = Colors.white.withValues(alpha: 0.7));
      }
    }

    // Left chain
    final leftChain = <Offset>[];
    for (double y = fw; y <= h - fw; y += ds) {
      leftChain.add(Offset(fw / 2, y));
    }
    drawChain(leftChain);

    // Right chain
    final rightChain = <Offset>[];
    for (double y = fw; y <= h - fw; y += ds) {
      rightChain.add(Offset(w - fw / 2, y));
    }
    drawChain(rightChain);

    // Top chain
    final topChain = <Offset>[];
    for (double x = fw; x <= w - fw; x += ds) {
      topChain.add(Offset(x, fw / 2));
    }
    drawChain(topChain);

    // Bottom chain
    final bottomChain = <Offset>[];
    for (double x = fw; x <= w - fw; x += ds) {
      bottomChain.add(Offset(x, h - fw / 2));
    }
    drawChain(bottomChain);

    // Corner gems (larger diamonds)
    for (final corner in [
      Offset(fw / 2, fw / 2),
      Offset(w - fw / 2, fw / 2),
      Offset(fw / 2, h - fw / 2),
      Offset(w - fw / 2, h - fw / 2),
    ]) {
      canvas.drawCircle(corner, 10, Paint()..color = chainGlow);
      final cp = Path()
        ..moveTo(corner.dx, corner.dy - 10)
        ..lineTo(corner.dx + 7, corner.dy)
        ..lineTo(corner.dx, corner.dy + 10)
        ..lineTo(corner.dx - 7, corner.dy)
        ..close();
      canvas.drawPath(cp, Paint()..color = chainDark);
      canvas.drawPath(cp, Paint()..color = chainColor);
      canvas.drawPath(
        cp,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  Future<void> restartLevel() async {
    await _loadLevel(manager.currentLevel);
    resumeEngine();
  }

  Future<void> loadNextLevel() async {
    final next = manager.currentLevel + 1;
    await _loadLevel(next > 15 ? 1 : next);
    resumeEngine();
  }
}

/// Renders the animated cave background underneath all gameplay. Lives inside
/// the camera `world` so it scales with the rest of the level.
class _BackgroundLayer extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  _BackgroundLayer() : super(priority: -100);

  @override
  void render(Canvas canvas) => game._renderCaveBg(canvas);
}

/// Renders the diamond-chain frame on top of everything (still inside world).
class _BorderLayer extends PositionComponent
    with HasGameReference<BubbleBlitzGame> {
  _BorderLayer() : super(priority: 150);

  @override
  void render(Canvas canvas) => game._renderDiamondBorderFrame(canvas);
}

/// Lightweight juicy pop effect: an expanding ring + sparkle dots that fade out.
/// Used when an enemy is defeated or a coin/bubble is collected.
class PopBurst extends PositionComponent {
  PopBurst({required Vector2 position, this.color = const Color(0xFFFFEB3B)})
      : super(position: position, priority: 50);

  final Color color;
  double _t = 0;
  static const double _dur = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _dur) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _dur).clamp(0.0, 1.0);
    final alpha = 1.0 - p;
    // Expanding ring
    canvas.drawCircle(
      Offset.zero,
      6 + p * 22,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Sparkle dots flying outward
    final dist = p * 22;
    for (int i = 0; i < 6; i++) {
      final ang = i * math.pi / 3;
      canvas.drawCircle(
        Offset(math.cos(ang) * dist, math.sin(ang) * dist),
        2.5 * (1 - p) + 0.8,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }
}
