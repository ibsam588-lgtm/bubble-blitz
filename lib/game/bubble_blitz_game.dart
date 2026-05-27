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

  // Touch controls state (set by overlay)
  int touchMove = 0; // -1, 0, 1
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

    AudioService.instance.playBgm();
  }

  @override
  void update(double dt) {
    super.update(dt);
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

    // Player vs enemy collision
    for (final e in enemies.toList()) {
      if (e.parent == null) continue;
      if (e.checkPlayerCollision(p)) {
        p.hit();
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
    final p = player;
    if (p == null) return;
    final dx = p.position.x - from.position.x;
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

    final left = _pressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressed.contains(LogicalKeyboardKey.keyA);
    final right = _pressed.contains(LogicalKeyboardKey.arrowRight) ||
        _pressed.contains(LogicalKeyboardKey.keyD);

    if (touchMove == 0) {
      if (left && !right) {
        p.moveLeft();
      } else if (right && !left) {
        p.moveRight();
      } else {
        p.stopMoving();
      }
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
  Color backgroundColor() {
    return currentSpec.bgPrimary;
  }

  void renderBackground(Canvas canvas) {}

  @override
  void render(Canvas canvas) {
    // Gradient background
    final rect = Rect.fromLTWH(0, 0, worldSize.x, worldSize.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [currentSpec.bgSecondary, currentSpec.bgPrimary],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Decorative floating bubbles in background
    final rand = math.Random(currentSpec.level);
    for (int i = 0; i < 14; i++) {
      final x = rand.nextDouble() * worldSize.x;
      final y = rand.nextDouble() * worldSize.y;
      final r = 6 + rand.nextDouble() * 14;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
    }
    super.render(canvas);
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
