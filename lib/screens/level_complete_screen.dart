import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/managers/game_manager.dart';
import '../utils/constants.dart';

class LevelCompleteScreen extends StatelessWidget {
  final GameManager manager;
  final Future<void> Function() onNext;
  final Future<void> Function() onRetry;
  final VoidCallback onExit;

  const LevelCompleteScreen({
    super.key,
    required this.manager,
    required this.onNext,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final stars = manager.starsEarned();
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL COMPLETE!',
              style: GoogleFonts.fredoka(
                color: AppConstants.accentYellow,
                fontSize: 36,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      color: i <= stars ? Colors.amber : Colors.white24,
                      size: 56,
                    )
                        .animate()
                        .scale(
                          duration: 300.ms,
                          delay: (200 * i).ms,
                          curve: Curves.elasticOut,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Score: ${manager.score}',
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22),
            ),
            Text(
              'Coins: ${manager.coinsCollected} 🪙',
              style: GoogleFonts.fredoka(color: AppConstants.accentYellow, fontSize: 18),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.bubbleBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => onNext(),
                icon: const Icon(Icons.arrow_forward),
                label: Text('NEXT LEVEL', style: GoogleFonts.fredoka(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.bubbleOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: Text('RETRY', style: GoogleFonts.fredoka(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: onExit,
                icon: const Icon(Icons.home),
                label: Text('MAIN MENU', style: GoogleFonts.fredoka(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
