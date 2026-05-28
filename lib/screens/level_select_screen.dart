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
        backgroundColor: AppConstants.uiDark,
        title: Text(
          'Arcade Stages',
          style: GoogleFonts.fredoka(color: AppConstants.foamWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.foamWhite),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.uiDark, AppConstants.uiPanel],
          ),
        ),
        child: ListView(
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
      ),
    );
  }

  Widget _worldHeader(int world) {
    final name = ['Waterfall Grove', 'Cloud Pines', 'Dragon Canopy'][world - 1];
    final color = [
      AppConstants.world1Primary,
      AppConstants.world2Primary,
      AppConstants.world3Primary,
    ][world - 1];
    final icon = [
      Icons.cloud_queue_rounded,
      Icons.forest_rounded,
      Icons.water_drop_rounded,
    ][world - 1];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.foamWhite, size: 24),
          const SizedBox(width: 12),
          Text(
            'World $world: $name',
            style: GoogleFonts.fredoka(
              color: AppConstants.foamWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? spec.bgPrimary : AppConstants.uiCard,
          borderRadius: BorderRadius.circular(8),
          border: spec.isBoss
              ? Border.all(color: AppConstants.accentYellow, width: 2)
              : Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            if (unlocked)
              BoxShadow(
                color: spec.bgPrimary.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock, color: Colors.white70, size: 20)
            else
              Text(
                spec.isBoss ? 'B' : '${spec.level}',
                style: GoogleFonts.fredoka(
                  color: AppConstants.foamWhite,
                  fontSize: spec.isBoss ? 22 : 18,
                  fontWeight: FontWeight.w800,
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
