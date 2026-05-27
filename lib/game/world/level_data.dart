import 'package:flutter/material.dart';

import '../../utils/constants.dart';

enum EnemyKind { slime, ghost, fireImp, boss }

class PlatformSpec {
  final double x;
  final double y;
  final double width;
  final double height;
  final bool moving;
  final double moveRange;
  const PlatformSpec({
    required this.x,
    required this.y,
    required this.width,
    this.height = 18,
    this.moving = false,
    this.moveRange = 80,
  });
}

class EnemySpec {
  final EnemyKind kind;
  final double x;
  final double y;
  const EnemySpec(this.kind, this.x, this.y);
}

class CoinSpec {
  final double x;
  final double y;
  const CoinSpec(this.x, this.y);
}

class PowerupSpec {
  final String kind; // 'multi' | 'big'
  final double x;
  final double y;
  const PowerupSpec(this.kind, this.x, this.y);
}

class LevelSpec {
  final int level;
  final int world; // 1..3
  final String name;
  final Color bgPrimary;
  final Color bgSecondary;
  final Color platformColor;
  final List<PlatformSpec> platforms;
  final List<EnemySpec> enemies;
  final List<CoinSpec> coins;
  final List<PowerupSpec> powerups;
  final bool isBoss;
  final Offset playerSpawn;

  const LevelSpec({
    required this.level,
    required this.world,
    required this.name,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.platformColor,
    required this.platforms,
    required this.enemies,
    required this.coins,
    required this.powerups,
    required this.isBoss,
    required this.playerSpawn,
  });
}

class LevelData {
  static const double worldW = 480;
  static const double worldH = 800;

  static List<LevelSpec> all() => [
        // ===== World 1: Candy Kingdom =====
        LevelSpec(
          level: 1,
          world: 1,
          name: 'Candy Kingdom 1',
          bgPrimary: AppConstants.world1Primary,
          bgSecondary: AppConstants.world1Secondary,
          platformColor: Color(0xFFFF80AB),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW), // ground
            PlatformSpec(x: 80, y: 600, width: 140),
            PlatformSpec(x: 280, y: 480, width: 140),
            PlatformSpec(x: 60, y: 360, width: 120),
            PlatformSpec(x: 300, y: 240, width: 140),
          ],
          enemies: [
            EnemySpec(EnemyKind.slime, 140, 580),
            EnemySpec(EnemyKind.slime, 340, 460),
          ],
          coins: [
            CoinSpec(120, 560),
            CoinSpec(160, 560),
            CoinSpec(320, 440),
            CoinSpec(360, 440),
            CoinSpec(100, 320),
            CoinSpec(340, 200),
          ],
          powerups: [],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 2,
          world: 1,
          name: 'Candy Kingdom 2',
          bgPrimary: AppConstants.world1Primary,
          bgSecondary: AppConstants.world1Secondary,
          platformColor: Color(0xFFFF80AB),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 40, y: 640, width: 110),
            PlatformSpec(x: 200, y: 560, width: 100),
            PlatformSpec(x: 340, y: 480, width: 110),
            PlatformSpec(x: 180, y: 360, width: 130),
            PlatformSpec(x: 40, y: 240, width: 120),
            PlatformSpec(x: 320, y: 180, width: 130),
          ],
          enemies: [
            EnemySpec(EnemyKind.slime, 80, 620),
            EnemySpec(EnemyKind.slime, 360, 460),
            EnemySpec(EnemyKind.slime, 220, 340),
          ],
          coins: [
            CoinSpec(60, 600), CoinSpec(220, 540), CoinSpec(360, 460),
            CoinSpec(220, 340), CoinSpec(80, 220), CoinSpec(360, 160),
            CoinSpec(160, 600), CoinSpec(260, 540),
          ],
          powerups: [PowerupSpec('multi', 180, 340)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 3,
          world: 1,
          name: 'Candy Kingdom 3',
          bgPrimary: AppConstants.world1Primary,
          bgSecondary: AppConstants.world1Secondary,
          platformColor: Color(0xFFE91E63),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 100, y: 640, width: 80, moving: true),
            PlatformSpec(x: 260, y: 560, width: 100),
            PlatformSpec(x: 60, y: 460, width: 110),
            PlatformSpec(x: 300, y: 380, width: 120),
            PlatformSpec(x: 80, y: 280, width: 110),
            PlatformSpec(x: 280, y: 180, width: 140),
          ],
          enemies: [
            EnemySpec(EnemyKind.slime, 280, 540),
            EnemySpec(EnemyKind.slime, 100, 440),
            EnemySpec(EnemyKind.slime, 320, 360),
            EnemySpec(EnemyKind.slime, 320, 160),
          ],
          coins: [
            CoinSpec(120, 620), CoinSpec(280, 540), CoinSpec(80, 440),
            CoinSpec(320, 360), CoinSpec(100, 260), CoinSpec(300, 160),
            CoinSpec(360, 160),
          ],
          powerups: [PowerupSpec('big', 60, 440)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 4,
          world: 1,
          name: 'Candy Kingdom 4',
          bgPrimary: AppConstants.world1Primary,
          bgSecondary: AppConstants.world1Secondary,
          platformColor: Color(0xFFAD1457),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 60, y: 640, width: 90),
            PlatformSpec(x: 200, y: 580, width: 80, moving: true, moveRange: 100),
            PlatformSpec(x: 340, y: 500, width: 100),
            PlatformSpec(x: 60, y: 420, width: 100),
            PlatformSpec(x: 220, y: 340, width: 100),
            PlatformSpec(x: 360, y: 260, width: 90),
            PlatformSpec(x: 80, y: 200, width: 120),
          ],
          enemies: [
            EnemySpec(EnemyKind.slime, 80, 620),
            EnemySpec(EnemyKind.slime, 360, 480),
            EnemySpec(EnemyKind.slime, 100, 400),
            EnemySpec(EnemyKind.slime, 240, 320),
            EnemySpec(EnemyKind.slime, 100, 180),
          ],
          coins: [
            CoinSpec(80, 600), CoinSpec(220, 560), CoinSpec(360, 480),
            CoinSpec(80, 400), CoinSpec(240, 320), CoinSpec(380, 240),
            CoinSpec(100, 180), CoinSpec(160, 180),
          ],
          powerups: [PowerupSpec('multi', 360, 240)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 5,
          world: 1,
          name: 'Candy King Boss',
          bgPrimary: Color(0xFFAD1457),
          bgSecondary: Color(0xFFFFB6C1),
          platformColor: Color(0xFF880E4F),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 40, y: 540, width: 120),
            PlatformSpec(x: 320, y: 540, width: 120),
            PlatformSpec(x: 180, y: 380, width: 120),
          ],
          enemies: [EnemySpec(EnemyKind.boss, 220, 200)],
          coins: [
            CoinSpec(60, 520), CoinSpec(120, 520),
            CoinSpec(340, 520), CoinSpec(400, 520),
            CoinSpec(220, 360),
          ],
          powerups: [PowerupSpec('big', 220, 360)],
          isBoss: true,
          playerSpawn: Offset(60, 700),
        ),

        // ===== World 2: Ghost Forest =====
        LevelSpec(
          level: 6,
          world: 2,
          name: 'Ghost Forest 1',
          bgPrimary: AppConstants.world2Primary,
          bgSecondary: AppConstants.world2Secondary,
          platformColor: Color(0xFF1B5E20),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 80, y: 620, width: 130),
            PlatformSpec(x: 280, y: 500, width: 130),
            PlatformSpec(x: 80, y: 380, width: 130),
            PlatformSpec(x: 280, y: 260, width: 130),
          ],
          enemies: [
            EnemySpec(EnemyKind.ghost, 200, 540),
            EnemySpec(EnemyKind.slime, 320, 480),
            EnemySpec(EnemyKind.ghost, 220, 320),
          ],
          coins: [
            CoinSpec(120, 600), CoinSpec(160, 600),
            CoinSpec(320, 480), CoinSpec(120, 360),
            CoinSpec(320, 240), CoinSpec(360, 240),
          ],
          powerups: [],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 7,
          world: 2,
          name: 'Ghost Forest 2',
          bgPrimary: AppConstants.world2Primary,
          bgSecondary: AppConstants.world2Secondary,
          platformColor: Color(0xFF2E7D32),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 60, y: 620, width: 100),
            PlatformSpec(x: 220, y: 560, width: 100, moving: true),
            PlatformSpec(x: 340, y: 460, width: 100),
            PlatformSpec(x: 100, y: 380, width: 120),
            PlatformSpec(x: 300, y: 280, width: 120),
            PlatformSpec(x: 60, y: 180, width: 120),
          ],
          enemies: [
            EnemySpec(EnemyKind.ghost, 240, 500),
            EnemySpec(EnemyKind.ghost, 360, 420),
            EnemySpec(EnemyKind.ghost, 140, 340),
            EnemySpec(EnemyKind.slime, 340, 260),
          ],
          coins: [
            CoinSpec(80, 600), CoinSpec(240, 540), CoinSpec(360, 440),
            CoinSpec(140, 360), CoinSpec(320, 260), CoinSpec(80, 160),
            CoinSpec(140, 160),
          ],
          powerups: [PowerupSpec('multi', 360, 440)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 8,
          world: 2,
          name: 'Ghost Forest 3',
          bgPrimary: AppConstants.world2Primary,
          bgSecondary: AppConstants.world2Secondary,
          platformColor: Color(0xFF388E3C),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 80, y: 640, width: 90),
            PlatformSpec(x: 240, y: 580, width: 90, moving: true),
            PlatformSpec(x: 60, y: 460, width: 110),
            PlatformSpec(x: 280, y: 400, width: 110),
            PlatformSpec(x: 120, y: 300, width: 100),
            PlatformSpec(x: 320, y: 220, width: 110),
            PlatformSpec(x: 40, y: 140, width: 120),
          ],
          enemies: [
            EnemySpec(EnemyKind.ghost, 280, 540),
            EnemySpec(EnemyKind.ghost, 100, 440),
            EnemySpec(EnemyKind.ghost, 340, 380),
            EnemySpec(EnemyKind.ghost, 160, 280),
            EnemySpec(EnemyKind.slime, 360, 200),
          ],
          coins: [
            CoinSpec(100, 620), CoinSpec(260, 560), CoinSpec(80, 440),
            CoinSpec(300, 380), CoinSpec(140, 280), CoinSpec(340, 200),
            CoinSpec(60, 120), CoinSpec(120, 120),
          ],
          powerups: [PowerupSpec('big', 320, 200)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 9,
          world: 2,
          name: 'Ghost Forest 4',
          bgPrimary: AppConstants.world2Primary,
          bgSecondary: AppConstants.world2Secondary,
          platformColor: Color(0xFF1B5E20),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 100, y: 640, width: 80, moving: true, moveRange: 120),
            PlatformSpec(x: 280, y: 560, width: 100),
            PlatformSpec(x: 80, y: 460, width: 100),
            PlatformSpec(x: 240, y: 360, width: 100, moving: true),
            PlatformSpec(x: 80, y: 260, width: 110),
            PlatformSpec(x: 300, y: 160, width: 130),
          ],
          enemies: [
            EnemySpec(EnemyKind.fireImp, 300, 540),
            EnemySpec(EnemyKind.ghost, 100, 440),
            EnemySpec(EnemyKind.ghost, 260, 340),
            EnemySpec(EnemyKind.ghost, 100, 240),
            EnemySpec(EnemyKind.fireImp, 340, 140),
          ],
          coins: [
            CoinSpec(120, 620), CoinSpec(300, 540), CoinSpec(100, 440),
            CoinSpec(260, 340), CoinSpec(100, 240), CoinSpec(320, 140),
            CoinSpec(380, 140),
          ],
          powerups: [PowerupSpec('multi', 80, 240)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 10,
          world: 2,
          name: 'Forest Phantom Boss',
          bgPrimary: Color(0xFF0D3D14),
          bgSecondary: Color(0xFF1B5E20),
          platformColor: Color(0xFF004D40),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 60, y: 520, width: 120),
            PlatformSpec(x: 300, y: 520, width: 120),
            PlatformSpec(x: 180, y: 360, width: 120),
          ],
          enemies: [EnemySpec(EnemyKind.boss, 220, 200)],
          coins: [
            CoinSpec(80, 500), CoinSpec(140, 500),
            CoinSpec(320, 500), CoinSpec(380, 500),
            CoinSpec(220, 340),
          ],
          powerups: [PowerupSpec('big', 220, 340)],
          isBoss: true,
          playerSpawn: Offset(60, 700),
        ),

        // ===== World 3: Fire Volcano =====
        LevelSpec(
          level: 11,
          world: 3,
          name: 'Fire Volcano 1',
          bgPrimary: AppConstants.world3Primary,
          bgSecondary: AppConstants.world3Secondary,
          platformColor: Color(0xFFBF360C),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 80, y: 620, width: 120),
            PlatformSpec(x: 280, y: 500, width: 120),
            PlatformSpec(x: 80, y: 380, width: 120),
            PlatformSpec(x: 280, y: 260, width: 120),
          ],
          enemies: [
            EnemySpec(EnemyKind.fireImp, 120, 580),
            EnemySpec(EnemyKind.fireImp, 320, 460),
            EnemySpec(EnemyKind.fireImp, 320, 240),
          ],
          coins: [
            CoinSpec(120, 600), CoinSpec(320, 480), CoinSpec(120, 360),
            CoinSpec(320, 240), CoinSpec(360, 240),
          ],
          powerups: [],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 12,
          world: 3,
          name: 'Fire Volcano 2',
          bgPrimary: AppConstants.world3Primary,
          bgSecondary: AppConstants.world3Secondary,
          platformColor: Color(0xFFD84315),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 60, y: 640, width: 90, moving: true),
            PlatformSpec(x: 220, y: 560, width: 100),
            PlatformSpec(x: 340, y: 460, width: 100),
            PlatformSpec(x: 80, y: 380, width: 120),
            PlatformSpec(x: 280, y: 260, width: 120),
            PlatformSpec(x: 80, y: 160, width: 120),
          ],
          enemies: [
            EnemySpec(EnemyKind.fireImp, 240, 540),
            EnemySpec(EnemyKind.fireImp, 360, 440),
            EnemySpec(EnemyKind.fireImp, 120, 360),
            EnemySpec(EnemyKind.fireImp, 320, 240),
            EnemySpec(EnemyKind.ghost, 120, 140),
          ],
          coins: [
            CoinSpec(80, 620), CoinSpec(240, 540), CoinSpec(360, 440),
            CoinSpec(120, 360), CoinSpec(320, 240), CoinSpec(100, 140),
            CoinSpec(160, 140),
          ],
          powerups: [PowerupSpec('multi', 320, 240)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 13,
          world: 3,
          name: 'Fire Volcano 3',
          bgPrimary: AppConstants.world3Primary,
          bgSecondary: AppConstants.world3Secondary,
          platformColor: Color(0xFFBF360C),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 80, y: 640, width: 80, moving: true, moveRange: 140),
            PlatformSpec(x: 240, y: 580, width: 100),
            PlatformSpec(x: 80, y: 460, width: 110),
            PlatformSpec(x: 280, y: 380, width: 110, moving: true),
            PlatformSpec(x: 120, y: 280, width: 110),
            PlatformSpec(x: 320, y: 180, width: 110),
            PlatformSpec(x: 40, y: 100, width: 130),
          ],
          enemies: [
            EnemySpec(EnemyKind.fireImp, 280, 560),
            EnemySpec(EnemyKind.fireImp, 100, 440),
            EnemySpec(EnemyKind.fireImp, 320, 360),
            EnemySpec(EnemyKind.fireImp, 160, 260),
            EnemySpec(EnemyKind.ghost, 360, 160),
          ],
          coins: [
            CoinSpec(100, 620), CoinSpec(280, 560), CoinSpec(120, 440),
            CoinSpec(320, 360), CoinSpec(160, 260), CoinSpec(360, 160),
            CoinSpec(60, 80), CoinSpec(140, 80),
          ],
          powerups: [PowerupSpec('big', 80, 440)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 14,
          world: 3,
          name: 'Fire Volcano 4',
          bgPrimary: AppConstants.world3Primary,
          bgSecondary: AppConstants.world3Secondary,
          platformColor: Color(0xFFE65100),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 100, y: 640, width: 80, moving: true),
            PlatformSpec(x: 280, y: 560, width: 100, moving: true),
            PlatformSpec(x: 60, y: 460, width: 100),
            PlatformSpec(x: 240, y: 360, width: 100),
            PlatformSpec(x: 60, y: 260, width: 110),
            PlatformSpec(x: 280, y: 180, width: 130),
            PlatformSpec(x: 60, y: 100, width: 130),
          ],
          enemies: [
            EnemySpec(EnemyKind.fireImp, 120, 620),
            EnemySpec(EnemyKind.fireImp, 320, 540),
            EnemySpec(EnemyKind.fireImp, 100, 440),
            EnemySpec(EnemyKind.fireImp, 280, 340),
            EnemySpec(EnemyKind.ghost, 100, 240),
            EnemySpec(EnemyKind.ghost, 320, 160),
          ],
          coins: [
            CoinSpec(120, 620), CoinSpec(320, 540), CoinSpec(80, 440),
            CoinSpec(280, 340), CoinSpec(80, 240), CoinSpec(300, 160),
            CoinSpec(360, 160), CoinSpec(100, 80), CoinSpec(160, 80),
          ],
          powerups: [PowerupSpec('multi', 60, 240), PowerupSpec('big', 280, 160)],
          isBoss: false,
          playerSpawn: Offset(60, 700),
        ),
        LevelSpec(
          level: 15,
          world: 3,
          name: 'Volcano Dragon Boss',
          bgPrimary: Color(0xFF7F0000),
          bgSecondary: Color(0xFFFF6F00),
          platformColor: Color(0xFF3E2723),
          platforms: [
            PlatformSpec(x: 0, y: 760, width: worldW),
            PlatformSpec(x: 40, y: 500, width: 130),
            PlatformSpec(x: 310, y: 500, width: 130),
            PlatformSpec(x: 175, y: 340, width: 130),
          ],
          enemies: [EnemySpec(EnemyKind.boss, 220, 180)],
          coins: [
            CoinSpec(60, 480), CoinSpec(120, 480),
            CoinSpec(330, 480), CoinSpec(390, 480),
            CoinSpec(220, 320),
          ],
          powerups: [
            PowerupSpec('big', 220, 320),
            PowerupSpec('multi', 60, 480),
          ],
          isBoss: true,
          playerSpawn: Offset(60, 700),
        ),
      ];

  static LevelSpec byLevel(int level) {
    final list = all();
    return list.firstWhere((l) => l.level == level, orElse: () => list.first);
  }
}
