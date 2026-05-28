import 'package:flame/components.dart';

import '../components/coin.dart';
import '../components/enemy_types.dart';
import '../components/platform.dart';
import '../components/powerup.dart';
import 'level_data.dart';

class Level {
  final LevelSpec spec;
  Level(this.spec);

  List<Component> build() {
    final out = <Component>[];
    for (final p in spec.platforms) {
      out.add(GamePlatform(spec: p, color: spec.platformColor, world: spec.world));
    }
    for (final e in spec.enemies) {
      switch (e.kind) {
        case EnemyKind.slime:
          out.add(SlimeEnemy(position: Vector2(e.x, e.y)));
          break;
        case EnemyKind.ghost:
          out.add(GhostEnemy(position: Vector2(e.x, e.y)));
          break;
        case EnemyKind.fireImp:
          out.add(FireImpEnemy(position: Vector2(e.x, e.y)));
          break;
        case EnemyKind.boss:
          out.add(BossEnemy(position: Vector2(e.x, e.y)));
          break;
      }
    }
    for (final c in spec.coins) {
      out.add(Coin(position: Vector2(c.x, c.y)));
    }
    for (final p in spec.powerups) {
      out.add(Powerup(position: Vector2(p.x, p.y), kind: p.kind));
    }
    return out;
  }
}
