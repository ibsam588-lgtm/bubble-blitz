import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/managers/game_manager.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';

class GameOverScreen extends StatelessWidget {
  final GameManager manager;
  final Future<void> Function() onContinueWithCoins;
  final Future<void> Function() onContinueWithAd;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameOverScreen({
    super.key,
    required this.manager,
    required this.onContinueWithCoins,
    required this.onContinueWithAd,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final coins = SaveService.instance.data.coins;
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style: GoogleFonts.fredoka(
                color: Colors.red,
                fontSize: 56,
                shadows: const [
                  Shadow(blurRadius: 8, color: Colors.black, offset: Offset(2, 2)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${manager.score}',
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 32),
            _btn(
              icon: Icons.play_circle,
              color: AppConstants.bubbleOrange,
              label: 'Watch Ad to Continue',
              onTap: onContinueWithAd,
            ),
            const SizedBox(height: 12),
            _btn(
              icon: Icons.monetization_on,
              color: AppConstants.accentYellow,
              textColor: Colors.black,
              label: 'Use ${AppConstants.continueCost} 🪙 to Continue ($coins)',
              onTap: onContinueWithCoins,
            ),
            const SizedBox(height: 12),
            _btn(
              icon: Icons.refresh,
              color: AppConstants.bubbleBlue,
              label: 'Restart',
              onTap: () async => onRestart(),
            ),
            const SizedBox(height: 12),
            _btn(
              icon: Icons.home,
              color: Colors.white24,
              label: 'Main Menu',
              onTap: () async => onExit(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required String label,
    required Future<void> Function() onTap,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      width: 280,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: () => onTap(),
        icon: Icon(icon),
        label: Text(label, style: GoogleFonts.fredoka(fontSize: 15)),
      ),
    );
  }
}
