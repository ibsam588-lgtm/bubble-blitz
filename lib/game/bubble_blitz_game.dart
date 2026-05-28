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
    camera.viewfinder.visibleGameSize = worldSize;
    camera.viewfinder.anchor = Anchor.topLeft;
    await _loadLevel(initialLevel);
    add(GameHud());
  }

  Future<void> _loadLevel(int level) async {
    _ended = false;
    currentSpec = LevelData.byLevel(level);
    manager.reset(level);

    children.whereType<GamePlatform>().forEach(remove);
    children.whereType<Enemy>().forEach(remove);
    children.whereType<Bubble>().forEach(remove);
    children.whereType<Coin>().forEach(remove);
    children.whereType<Powerup>().forEach(remove);
    children.whereType<Player>().forEach(remove);
    children.whereType<EnemyProjectile>().forEach(remove);
    platforms.clear();
    enemies.clear();
    bubbles.clear();
    coins.clear();
    powerups.clear();

    final levelObj = Level(currentSpec);
    for (final c in levelObj.build()) {
      add(c);
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
    add(p);
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

    if (touchMove < 0)      p.moveLeft();
    else if (touchMove > 0) p.moveRight();

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
        add(b); bubbles.add(b);
      }
    } else {
      final b = Bubble(
        position: p.position + Vector2(p.size.x / 2, p.size.y / 2),
        vx: dir * 280, isBig: big,
      );
      add(b); bubbles.add(b);
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
    add(proj);
  }

  void spawnMinion(Enemy boss) {
    final slime = SlimeEnemy(
        position: Vector2(boss.position.x + 20, boss.position.y + boss.size.y));
    add(slime); enemies.add(slime);
  }

  void spawnPopEffect(Vector2 at) {
    AudioService.instance.playSfx(Assets.flameBubblePop);
  }

  void onEnemyDefeated(Enemy e) {
    manager.addScore(e.scoreValue);
    AudioService.instance.playSfx(Assets.flameBubblePop);
    final c = Coin(position: e.position.clone());
    add(c); coins.add(c);
  }

  void onCoinCollected(Coin c) {
    manager.addCoin();
    AudioService.instance.playSfx(Assets.flameCoinCollect);
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
    final pos = info.eventPosition.global;
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
    _pressed..clear()..addAll(keysPressed);
    final p = player;
    if (p == null) return KeyEventResult.ignored;

    final left = _pressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressed.contains(LogicalKeyboardKey.keyA);
    final right = _pressed.contains(LogicalKeyboardKey.arrowRight) ||
        _pressed.contains(LogicalKeyboardKey.keyD);

    if (touchMove == 0) {
      if (left && !right)       p.moveLeft();
      else if (right && !left)  p.moveRight();
      else                      p.stopMoving();
    }

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

  // ── Background rendering ─────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    switch (currentSpec.world) {
      case 1: _renderJungleBg(canvas); break;
      case 2: _renderForestBg(canvas); break;
      case 3: _renderVolcanoBg(canvas); break;
      default: _renderDefaultBg(canvas);
    }
    super.render(canvas);
  }

  void _renderJungleBg(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Sky gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFB2DFDB), Color(0xFF81C784)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Distant rolling hills — 3 layers
    _drawHills(canvas, w, h, 0.55, const Color(0xFF66BB6A));
    _drawHills(canvas, w, h, 0.68, const Color(0xFF4CAF50));
    _drawHills(canvas, w, h, 0.80, const Color(0xFF388E3C));

    // Floor tile strip
    final floorY = h - 40.0;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, 40),
      Paint()..color = const Color(0xFF2E7D32),
    );
    // Grass tufts
    for (double fx = 4; fx < w; fx += 18) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, floorY + 2), width: 14, height: 8),
        Paint()..color = const Color(0xFF76FF03),
      );
    }

    // Bamboo stalks on edges
    _drawBambooStalk(canvas, 12, 0, h - 40);
    _drawBambooStalk(canvas, 38, 0, h - 40);
    _drawBambooStalk(canvas, w - 18, 0, h - 40);
    _drawBambooStalk(canvas, w - 44, 0, h - 40);

    // Small flowers scattered
    final rand = math.Random(42);
    for (int i = 0; i < 10; i++) {
      final fx = rand.nextDouble() * w;
      final fy = floorY - rand.nextDouble() * 20;
      _drawFlower(canvas, fx, fy);
    }
  }

  void _drawHills(Canvas canvas, double w, double h, double yFrac, Color color) {
    final baseY = h * yFrac;
    final path = Path()..moveTo(0, h);
    final steps = 8;
    for (int i = 0; i <= steps; i++) {
      final x = w * i / steps;
      final y = baseY + math.sin(i * 0.8 + 1.0) * 40;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawBambooStalk(Canvas canvas, double x, double yTop, double yBot) {
    final paint = Paint()..color = const Color(0xFF558B2F);
    canvas.drawRect(Rect.fromLTWH(x - 5, yTop, 10, yBot - yTop), paint);
    // Nodes
    final nodePaint = Paint()..color = const Color(0xFF33691E);
    for (double y = yTop + 16; y < yBot; y += 20) {
      canvas.drawRect(Rect.fromLTWH(x - 6, y, 12, 3), nodePaint);
      // Leaf
      final leaf = Path()
        ..moveTo(x + 5, y)
        ..quadraticBezierTo(x + 20, y - 8, x + 16, y + 4)
        ..quadraticBezierTo(x + 8, y + 6, x + 5, y)
        ..close();
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF76FF03).withValues(alpha: 0.7));
    }
  }

  void _drawFlower(Canvas canvas, double x, double y) {
    const petals = [Colors.white, Color(0xFFFFF176), Color(0xFFFFCDD2)];
    final color = petals[((x + y).toInt()).abs() % petals.length];
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      canvas.drawCircle(
        Offset(x + math.cos(a) * 3, y + math.sin(a) * 3), 2.5,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(Offset(x, y), 2, Paint()..color = const Color(0xFFFFEB3B));
  }

  void _renderForestBg(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Dark sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2A), Color(0xFF1A2E1A)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Tree silhouette layers (back to front)
    _drawTreeLayer(canvas, w, h, 0.48, const Color(0xFF0D1A0D), 8);
    _drawTreeLayer(canvas, w, h, 0.62, const Color(0xFF142814), 6);
    _drawTreeLayer(canvas, w, h, 0.76, const Color(0xFF1B3A1B), 5);

    // Vines hanging from top
    final rand = math.Random(77);
    for (int i = 0; i < 8; i++) {
      final vx = rand.nextDouble() * w;
      final vineLen = 80 + rand.nextDouble() * 120;
      final sway = math.sin(_bgT * 0.6 + i) * 6;
      _drawVine(canvas, vx + sway, vineLen);
    }

    // Firefly dots
    final ffRand = math.Random(55);
    for (int i = 0; i < 20; i++) {
      final fx = ffRand.nextDouble() * w;
      final fy = ffRand.nextDouble() * (h * 0.75);
      final blink = (math.sin(_bgT * 2.5 + i * 1.3) + 1) / 2;
      canvas.drawCircle(
        Offset(fx, fy), 2.5,
        Paint()..color = const Color(0xFFFFEB3B).withValues(alpha: blink * 0.8),
      );
    }

    // Dark floor
    canvas.drawRect(
      Rect.fromLTWH(0, h - 40, w, 40),
      Paint()..color = const Color(0xFF0D1A0D),
    );
  }

  void _drawTreeLayer(Canvas canvas, double w, double h, double yFrac, Color color, int count) {
    final rand = math.Random((yFrac * 100).toInt());
    for (int i = 0; i < count; i++) {
      final tx = rand.nextDouble() * w;
      final treeH = 120 + rand.nextDouble() * 80;
      final treeW = 50 + rand.nextDouble() * 40;
      final ty = h * yFrac - treeH;

      // Trunk
      canvas.drawRect(
        Rect.fromLTWH(tx - 6, ty + treeH * 0.6, 12, treeH * 0.4),
        Paint()..color = color,
      );
      // Canopy layers
      for (int layer = 0; layer < 3; layer++) {
        final ly = ty + layer * treeH * 0.2;
        final lw = treeW * (1.0 - layer * 0.25);
        final path = Path()
          ..moveTo(tx, ly)
          ..lineTo(tx - lw / 2, ly + treeH * 0.35)
          ..lineTo(tx + lw / 2, ly + treeH * 0.35)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
      }
    }
  }

  void _drawVine(Canvas canvas, double x, double length) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(x, 0);
    for (double y = 10; y < length; y += 10) {
      path.lineTo(x + math.sin(y * 0.3) * 5, y);
    }
    canvas.drawPath(path, paint);
    // Leaf at end
    final leaf = Path()
      ..moveTo(x, length)
      ..quadraticBezierTo(x + 12, length - 6, x + 8, length + 6)
      ..quadraticBezierTo(x + 2, length + 8, x, length)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.6));
  }

  void _renderVolcanoBg(Canvas canvas) {
    final w = worldSize.x;
    final h = worldSize.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Dark red sky
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A0000),
            const Color(0xFF4A0000),
            const Color(0xFFBF360C).withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Jagged rock silhouettes on sides
    _drawRockSilhouette(canvas, 0, h, true);
    _drawRockSilhouette(canvas, w, h, false);

    // Lava pool glow at bottom (pulsing)
    final pulse = (math.sin(_bgT * 2.2) + 1) / 2;
    final lavaGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: 1.0,
        colors: [
          const Color(0xFFFF6F00).withValues(alpha: 0.4 + pulse * 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, h - 200, w, 200));
    canvas.drawRect(Rect.fromLTWH(0, h - 200, w, 200), lavaGlow);

    // Lava floor
    canvas.drawRect(
      Rect.fromLTWH(0, h - 40, w, 40),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFBF360C), const Color(0xFFFF6F00)],
        ).createShader(Rect.fromLTWH(0, h - 40, w, 40)),
    );

    // Ember particles floating upward
    final eRand = math.Random(99);
    for (int i = 0; i < 18; i++) {
      final baseX = eRand.nextDouble() * w;
      final speed = 30 + eRand.nextDouble() * 60;
      final ey = (h - (_bgT * speed * 0.5 + i * 44) % h).clamp(0.0, h);
      final glow = (math.sin(_bgT * 3 + i) + 1) / 2;
      canvas.drawCircle(
        Offset(baseX + math.sin(_bgT * 1.5 + i) * 10, ey),
        1.5 + glow * 1.5,
        Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.5 + glow * 0.4),
      );
    }
  }

  void _drawRockSilhouette(Canvas canvas, double xBase, double h, bool isLeft) {
    final path = Path();
    final rand = math.Random(isLeft ? 11 : 22);
    final xSign = isLeft ? 1.0 : -1.0;
    path.moveTo(xBase, h);
    path.lineTo(xBase, h * 0.3);
    double y = h * 0.3;
    while (y < h) {
      final jag = rand.nextDouble() * 60 + 20;
      final jx = xBase + xSign * (30 + rand.nextDouble() * 50);
      path.lineTo(jx, y + jag / 2);
      path.lineTo(xBase, y + jag);
      y += jag;
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF212121));
  }

  void _renderDefaultBg(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, worldSize.x, worldSize.y);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [currentSpec.bgSecondary, currentSpec.bgPrimary],
        ).createShader(rect),
    );
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
