import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/bubble_blitz_game.dart';
import '../game/managers/game_manager.dart';
import '../services/ads_service.dart';
import '../services/save_service.dart';
import '../utils/constants.dart';
import 'game_over_screen.dart';
import 'level_complete_screen.dart';

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameManager manager;
  late final BubbleBlitzGame game;
  bool _showGameOver = false;
  bool _showLevelComplete = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    manager = GameManager();
    game = BubbleBlitzGame(
      initialLevel: widget.level,
      manager: manager,
      onGameOver: (_) => setState(() => _showGameOver = true),
      onLevelComplete: (_) => setState(() => _showLevelComplete = true),
    );
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        game.pauseEngine();
      } else {
        game.resumeEngine();
      }
    });
  }

  Future<void> _restart() async {
    setState(() {
      _showGameOver = false;
      _showLevelComplete = false;
      _paused = false;
    });
    await game.restartLevel();
  }

  Future<void> _next() async {
    setState(() {
      _showLevelComplete = false;
      _showGameOver = false;
      _paused = false;
    });
    await game.loadNextLevel();
  }

  void _exit() {
    context.go('/menu');
  }

  Future<void> _continueWithCoins() async {
    final ok = await SaveService.instance.spendCoins(AppConstants.continueCost);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins to continue')),
        );
      }
      return;
    }
    manager.revive();
    setState(() => _showGameOver = false);
    game.resumeEngine();
  }

  Future<void> _continueWithAd() async {
    final earned = await AdsService.instance.showRewardedAd();
    if (!earned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not available. Try again soon.')),
        );
      }
      return;
    }
    manager.revive();
    setState(() => _showGameOver = false);
    game.resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: game)),
            Positioned(
              left: 16,
              bottom: 16,
              child: _dpad(),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _actionButtons(),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white, size: 32),
                onPressed: _togglePause,
              ),
            ),
            if (_paused && !_showGameOver && !_showLevelComplete)
              _pauseOverlay(),
            if (_showGameOver)
              Positioned.fill(
                child: GameOverScreen(
                  manager: manager,
                  onContinueWithCoins: _continueWithCoins,
                  onContinueWithAd: _continueWithAd,
                  onRestart: _restart,
                  onExit: _exit,
                ),
              ),
            if (_showLevelComplete)
              Positioned.fill(
                child: LevelCompleteScreen(
                  manager: manager,
                  onNext: _next,
                  onRetry: _restart,
                  onExit: _exit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dpad() {
    return Row(
      children: [
        _ctrlButton(
          icon: Icons.arrow_left,
          onPressDown: () => game.touchMove = -1,
          onPressUp: () {
            if (game.touchMove < 0) game.touchMove = 0;
          },
        ),
        const SizedBox(width: 8),
        _ctrlButton(
          icon: Icons.arrow_right,
          onPressDown: () => game.touchMove = 1,
          onPressUp: () {
            if (game.touchMove > 0) game.touchMove = 0;
          },
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        _ctrlButton(
          label: 'JUMP',
          color: AppConstants.bubbleOrange,
          onPressDown: () => game.touchJump = true,
        ),
        const SizedBox(width: 10),
        _ctrlButton(
          label: 'FIRE',
          color: AppConstants.bubbleBlue,
          onPressDown: () => game.touchShoot = true,
        ),
      ],
    );
  }

  Widget _ctrlButton({
    IconData? icon,
    String? label,
    Color color = Colors.white24,
    VoidCallback? onPressDown,
    VoidCallback? onPressUp,
  }) {
    // Use Listener (raw pointer events) instead of GestureDetector so these
    // buttons are never stolen by the GameWidget's gesture arena. onPointerDown
    // fires the instant a finger touches the button — no tap-recognition delay.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onPressDown?.call(),
      onPointerUp: (_) => onPressUp?.call(),
      onPointerCancel: (_) => onPressUp?.call(),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 32)
            : Text(
                label ?? '',
                style: GoogleFonts.fredoka(color: Colors.white, fontSize: 14),
              ),
      ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 48),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _togglePause, child: const Text('RESUME')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _restart, child: const Text('RESTART')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _exit, child: const Text('QUIT')),
          ],
        ),
      ),
    );
  }
}
