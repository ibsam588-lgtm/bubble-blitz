import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/world/level_data.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = LevelData.all();
    final unlocked = SaveService.instance.data.unlockedLevels;
    final stars = SaveService.instance.data.levelStars;
    return Scaffold(
      backgroundColor: AppConstants.uiDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Levels', style: GoogleFonts.fredoka(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final world in [1, 2, 3]) ...[
            _worldHeader(world),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: levels.where((l) => l.world == world).map((l) {
                final isUnlocked = l.level <= unlocked;
                final s = stars[l.level] ?? 0;
                return _LevelTile(
                  spec: l,
                  unlocked: isUnlocked,
                  stars: s,
                  onTap: isUnlocked
                      ? () => context.go('/game/${l.level}')
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _worldHeader(int world) {
    final name = ['Candy Kingdom', 'Ghost Forest', 'Fire Volcano'][world - 1];
    final color = [
      AppConstants.world1Primary,
      AppConstants.world2Primary,
      AppConstants.world3Primary,
    ][world - 1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(['🍭', '👻', '🌋'][world - 1], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            'World $world: $name',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final LevelSpec spec;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;
  const _LevelTile({
    required this.spec,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? spec.bgPrimary : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: spec.isBoss
              ? Border.all(color: Colors.amber, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, color: Colors.white70, size: 20)
            else
              Text(
                spec.isBoss ? '👑' : '${spec.level}',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: spec.isBoss ? 22 : 18,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 3; i++)
                  Icon(
                    Icons.star,
                    color: i <= stars ? Colors.amber : Colors.white24,
                    size: 10,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
