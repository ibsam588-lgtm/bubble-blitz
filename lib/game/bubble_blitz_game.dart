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
import '../utils/constants.dart';
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
  }) {
    worldSize = Vector2(LevelData.worldW, LevelData.worldH);
    viewSize = worldSize.clone();
    currentSpec = LevelData.byLevel(initialLevel);
  }

  Player? player;
  Player? player2;
  final List<GamePlatform> platforms = [];
  final List<Enemy> enemies = [];
  final List<Bubble> bubbles = [];
  final List<Coin> coins = [];
  final List<Powerup> powerups = [];

  Vector2 worldSize = Vector2(LevelData.worldW, LevelData.worldH);
  Vector2 viewSize = Vector2(LevelData.worldW, LevelData.worldH);
  late LevelSpec currentSpec;
  bool _ended = false;
  double _bgT = 0;

  // Touch controls state (set by overlay)
  int touchMove = 0; // -1, 0, 1
  bool touchJump = false;
  bool touchShoot = false;

  Iterable<Player> get activePlayers sync* {
    final p1 = player;
    final p2 = player2;
    if (p1 != null && p1.parent != null) yield p1;
    if (p2 != null && p2.parent != null) yield p2;
  }

  @override
  Future<void> onLoad() async {
    worldSize = Vector2(LevelData.worldW, LevelData.worldH);
    viewSize = worldSize.clone();
    camera.viewfinder.visibleGameSize = viewSize;
    camera.viewfinder.anchor = Anchor.topLeft;

    await _loadLevel(initialLevel);
    add(GameHud());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    final worldAspect = worldSize.x / worldSize.y;
    final canvasAspect = size.x / size.y;
    if (canvasAspect < worldAspect) {
      viewSize = Vector2(worldSize.x, worldSize.x / canvasAspect);
    } else {
      viewSize = Vector2(worldSize.y * canvasAspect, worldSize.y);
    }
    camera.viewfinder.visibleGameSize = viewSize;
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  Future<void> _loadLevel(int level) async {
    _ended = false;
    currentSpec = LevelData.byLevel(level);
    manager.reset(level);

    // Clear previous
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
      (c) => c.id == charId,
      orElse: () => CharacterType.dragon,
    );
    final p = Player(
      position: Vector2(currentSpec.playerSpawn.dx, currentSpec.playerSpawn.dy),
      character: char,
    );
    add(p);
    player = p;

    final p2 = Player(
      position: Vector2(
        currentSpec.playerSpawn.dx + 46,
        currentSpec.playerSpawn.dy,
      ),
      character: CharacterType.phoenix,
    );
    add(p2);
    player2 = p2;

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

    // Apply touch / button inputs
    if (touchMove < 0) {
      p.moveLeft();
    } else if (touchMove > 0) {
      p.moveRight();
    } else {
      // Keyboard fallback handled in onKeyEvent
    }
    if (touchJump) {
      p.jump();
      touchJump = false;
    }
    if (touchShoot) {
      p.shoot();
      touchShoot = false;
    }

    // Players vs enemy collision
    for (final e in enemies.toList()) {
      if (e.parent == null) continue;
      for (final hero in activePlayers) {
        if (e.checkPlayerCollision(hero)) {
          hero.hit();
        }
      }
    }

    // Bubble cleanup tracking
    bubbles.removeWhere((b) => b.parent == null);
    enemies.removeWhere((e) => e.parent == null);
    coins.removeWhere((c) => c.parent == null);
    powerups.removeWhere((p) => p.parent == null);

    // Check player tapping bubble to pop trapped
    // (handled in onTapDown via spatial check)

    // Level complete: all non-boss enemies cleared OR boss defeated
    if (!manager.isLevelComplete && enemies.isEmpty) {
      manager.completeLevel();
      _ended = true;
      AudioService.instance.playSfx(Assets.flameLevelComplete);
      _finishLevel();
    }

    // Game over
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
          vx: dir * 240,
          vy: i * 60.0,
          isBig: big,
        );
        add(b);
        bubbles.add(b);
      }
    } else {
      final b = Bubble(
        position: p.position + Vector2(p.size.x / 2, p.size.y / 2),
        vx: dir * 280,
        isBig: big,
      );
      add(b);
      bubbles.add(b);
    }
  }

  void spawnEnemyProjectile(Enemy from) {
    final targets = activePlayers.toList();
    if (targets.isEmpty) return;
    targets.sort(
      (a, b) => (a.position - from.position).length.compareTo(
            (b.position - from.position).length,
          ),
    );
    final dx = targets.first.position.x - from.position.x;
    final dir = dx.sign;
    final proj = EnemyProjectile(
      position: from.position + from.size / 2,
      vx: dir * 150,
      vy: -50,
    );
    add(proj);
  }

  void spawnMinion(Enemy boss) {
    final slime = SlimeEnemy(
      position: Vector2(boss.position.x + 20, boss.position.y + boss.size.y),
    );
    add(slime);
    enemies.add(slime);
  }

  void spawnPopEffect(Vector2 at) {
    AudioService.instance.playSfx(Assets.flameBubblePop);
  }

  void onEnemyDefeated(Enemy e) {
    manager.addScore(e.scoreValue);
    AudioService.instance.playSfx(Assets.flameBubblePop);
    // Spawn a coin where the enemy died
    final c = Coin(position: e.position.clone());
    add(c);
    coins.add(c);
  }

  void onCoinCollected(Coin c) {
    manager.addCoin();
    AudioService.instance.playSfx(Assets.flameCoinCollect);
  }

  void onPowerupCollected(Powerup p) {
    if (p.kind == 'multi') {
      manager.multiBubbleShots += 3;
    } else if (p.kind == 'big') {
      manager.activateBigBubble();
    }
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
    // Pop nearby floating bubbles
    for (final b in bubbles.toList()) {
      if (b.trappedEnemy != null) {
        final d = (b.position - pos).length;
        if (d < b.radius + 16) {
          b.popByPlayer();
          return;
        }
      }
    }
  }

  // Keyboard fallback
  final Set<LogicalKeyboardKey> _pressed = {};

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _pressed
      ..clear()
      ..addAll(keysPressed);

    final p = player;
    if (p == null) return KeyEventResult.ignored;
    final p2 = player2;

    final left = _pressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressed.contains(LogicalKeyboardKey.numpad4);
    final right = _pressed.contains(LogicalKeyboardKey.arrowRight) ||
        _pressed.contains(LogicalKeyboardKey.numpad6);
    final p2Left = _pressed.contains(LogicalKeyboardKey.keyA);
    final p2Right = _pressed.contains(LogicalKeyboardKey.keyD);

    if (touchMove == 0) {
      if (left && !right) {
        p.moveLeft();
      } else if (right && !left) {
        p.moveRight();
      } else {
        p.stopMoving();
      }
    }
    if (p2 != null) {
      if (p2Left && !p2Right) {
        p2.moveLeft();
      } else if (p2Right && !p2Left) {
        p2.moveRight();
      } else {
        p2.stopMoving();
      }
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.numpad8 ||
          event.logicalKey == LogicalKeyboardKey.space) {
        p.jump();
      } else if (event.logicalKey == LogicalKeyboardKey.keyW) {
        p2?.jump();
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ ||
          event.logicalKey == LogicalKeyboardKey.keyZ ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        p.shoot();
      } else if (event.logicalKey == LogicalKeyboardKey.keyF ||
          event.logicalKey == LogicalKeyboardKey.shiftLeft) {
        p2?.shoot();
      }
    }

    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() {
    return currentSpec.bgPrimary;
  }

  void renderBackground(Canvas canvas) {}

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, viewSize.x, viewSize.y);
    final topColor = [
      AppConstants.world1Secondary,
      AppConstants.world2Secondary,
      AppConstants.world3Secondary,
    ][currentSpec.world - 1];
    final bottomColor = [
      const Color(0xFF7DC26D),
      const Color(0xFF2D6D38),
      const Color(0xFF18344B),
    ][currentSpec.world - 1];
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          topColor,
          Color.lerp(topColor, bottomColor, 0.25)!,
          bottomColor,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    _renderArcadeStage(canvas);

    final rand = math.Random(currentSpec.level);
    for (int i = 0; i < 12; i++) {
      final x = rand.nextDouble() * viewSize.x;
      final baseY = rand.nextDouble() * viewSize.y;
      final drift = (_bgT * (10 + rand.nextDouble() * 16)) % (viewSize.y + 80);
      final y = (baseY - drift + viewSize.y + 40) % (viewSize.y + 80) - 40;
      final r = 7 + rand.nextDouble() * 18;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(x - r * 0.28, y - r * 0.28),
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }
    super.render(canvas);
  }

  void _renderArcadeStage(Canvas canvas) {
    switch (currentSpec.world) {
      case 1:
        _renderWaterfallWorld(canvas);
        break;
      case 2:
        _renderPineWorld(canvas);
        break;
      default:
        _renderCanopyWorld(canvas);
        break;
    }
    _renderSideLogs(canvas);
    _renderGround(canvas);
  }

  void _renderWaterfallWorld(Canvas canvas) {
    final cliff = Paint()..color = const Color(0xFFB68A63);
    canvas.drawRect(Rect.fromLTWH(0, 0, viewSize.x, 760), cliff);
    for (double x = 0; x < viewSize.x; x += 58) {
      canvas.drawOval(
        Rect.fromLTWH(x - 12, 30 + (x % 130), 84, 140),
        Paint()..color = const Color(0xFF8E6548).withValues(alpha: 0.2),
      );
    }

    final falls = Rect.fromLTWH(viewSize.x * 0.28, 0, viewSize.x * 0.44, 760);
    canvas.drawRect(
      falls,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            AppConstants.waterfall,
            Color(0xFFC6ECFF),
            Color(0xFFFFFFFF),
          ],
        ).createShader(falls),
    );
    final streak = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (double x = falls.left + 18; x < falls.right; x += 32) {
      canvas.drawLine(Offset(x, 10), Offset(x - 18, 735), streak);
    }
    _drawHangingVines(canvas, 0);
    _drawHangingVines(canvas, viewSize.x - 34);
  }

  void _renderPineWorld(Canvas canvas) {
    final mountain = Paint()..color = const Color(0xFF8AA6C9);
    final farMountain = Path()
      ..moveTo(0, 302)
      ..lineTo(135, 160)
      ..lineTo(276, 302)
      ..lineTo(410, 178)
      ..lineTo(viewSize.x, 308)
      ..lineTo(viewSize.x, 760)
      ..lineTo(0, 760)
      ..close();
    canvas.drawPath(farMountain, mountain);
    canvas.drawPath(
      farMountain,
      Paint()..color = const Color(0xFF395F83).withValues(alpha: 0.25),
    );

    for (final cloud in [
      const Offset(120, 165),
      const Offset(320, 120),
      Offset(viewSize.x - 150, 190),
    ]) {
      _drawCloud(canvas, cloud);
    }
    for (double x = -20; x < viewSize.x; x += 42) {
      final h = 160 + 50 * math.sin(x * 0.05);
      _drawPine(canvas, Offset(x, 590), h);
    }
  }

  void _renderCanopyWorld(Canvas canvas) {
    _renderWaterfallWorld(canvas);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, viewSize.x, 760),
      Paint()..color = const Color(0xFF0B1730).withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(viewSize.x - 86, 88),
      36,
      Paint()..color = const Color(0xFFFFF3B1).withValues(alpha: 0.85),
    );
    for (double x = -70; x < viewSize.x; x += 150) {
      canvas.drawOval(
        Rect.fromLTWH(x, 70 + 28 * math.sin(x), 220, 140),
        Paint()..color = const Color(0xFF123A2D),
      );
    }
  }

  void _renderSideLogs(Canvas canvas) {
    for (final x in [8.0, viewSize.x - 24]) {
      final rect = Rect.fromLTWH(x, 18, 16, 724);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = AppConstants.bark,
      );
      for (double y = 28; y < 730; y += 28) {
        canvas.drawOval(
          Rect.fromLTWH(x - 2, y, 20, 12),
          Paint()..color = AppConstants.barkDark.withValues(alpha: 0.45),
        );
      }
      _drawHangingVines(canvas, x + 5);
    }
  }

  void _renderGround(Canvas canvas) {
    const top = 740.0;
    canvas.drawRect(
      Rect.fromLTWH(0, top, viewSize.x, viewSize.y - top),
      Paint()..color = const Color(0xFF2F8C36),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, top - 8, viewSize.x, 12),
      Paint()..color = AppConstants.moss,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, top + 12, math.min(488, viewSize.x + 16), 20),
        const Radius.circular(9),
      ),
      Paint()..color = AppConstants.bark,
    );
    canvas.drawLine(
      const Offset(0, top + 14),
      Offset(math.min(480, viewSize.x), top + 14),
      Paint()
        ..color = AppConstants.barkDark
        ..strokeWidth = 2,
    );
  }

  void _drawHangingVines(Canvas canvas, double x) {
    final vinePaint = Paint()
      ..color = AppConstants.vine.withValues(alpha: 0.78)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double y = 50; y < 680; y += 88) {
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 16, y + 28, x + 2, y + 64);
      canvas.drawPath(path, vinePaint);
      canvas.drawOval(
        Rect.fromLTWH(x + 4, y + 28, 8, 14),
        Paint()..color = AppConstants.moss.withValues(alpha: 0.9),
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset c) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawOval(Rect.fromLTWH(c.dx - 34, c.dy + 8, 74, 24), p);
    canvas.drawCircle(Offset(c.dx - 16, c.dy + 10), 18, p);
    canvas.drawCircle(Offset(c.dx + 10, c.dy + 3), 23, p);
    canvas.drawCircle(Offset(c.dx + 34, c.dy + 12), 15, p);
  }

  void _drawPine(Canvas canvas, Offset base, double height) {
    final trunk = Paint()..color = const Color(0xFF4D3526);
    final needles = Paint()..color = const Color(0xFF143B28);
    canvas.drawRect(
        Rect.fromLTWH(base.dx + 14, base.dy - height * 0.35, 8, height * 0.35),
        trunk);
    for (int i = 0; i < 4; i++) {
      final y = base.dy - height + i * height * 0.19;
      final w = height * (0.32 + i * 0.07);
      final path = Path()
        ..moveTo(base.dx + 18, y)
        ..lineTo(base.dx + 18 - w / 2, y + height * 0.24)
        ..lineTo(base.dx + 18 + w / 2, y + height * 0.24)
        ..close();
      canvas.drawPath(path, needles);
    }
  }

  Future<void> restartLevel() async {
    await _loadLevel(manager.currentLevel);
    resumeEngine();
  }

  Future<void> loadNextLevel() async {
    final next = manager.currentLevel + 1;
    if (next > 15) {
      // Game complete; loop to first level
      await _loadLevel(1);
    } else {
      await _loadLevel(next);
    }
    resumeEngine();
  }
}
