import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _showTutorial = false;

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
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen') ?? false;
    if (!seen) {
      game.pauseEngine();
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    game.resumeEngine();
    setState(() => _showTutorial = false);
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

  Future<bool> _onWillPop() async {
    if (_showGameOver || _showLevelComplete) {
      _exit();
      return false;
    }
    game.pauseEngine();
    final quit = await _showQuitDialog();
    if (quit == true) {
      _exit();
      return false;
    }
    if (!_paused) game.resumeEngine();
    return false;
  }

  Future<bool?> _showQuitDialog() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        title: Text(
          'Quit Game?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
              color: Colors.white, fontSize: 26),
        ),
        content: Text(
          'Your progress on this level will be lost.',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
              color: Colors.white70, fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: Text('KEEP PLAYING',
                style: GoogleFonts.fredoka(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('QUIT',
                style: GoogleFonts.fredoka(fontSize: 18)),
          ),
        ],
      ),
    );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: GameWidget(game: game)),

              // ── D-pad (bottom-left) ───────────────────────────────────
              Positioned(
                left: 12,
                bottom: 20,
                child: _dpad(),
              ),

              // ── Action buttons (bottom-right) ─────────────────────────
              Positioned(
                right: 12,
                bottom: 20,
                child: _actionButtons(),
              ),

              // ── Pause button (top-right) ──────────────────────────────
              Positioned(
                top: 8,
                right: 8,
                child: _pauseButton(),
              ),

              // ── Overlays ──────────────────────────────────────────────
              if (_paused && !_showGameOver && !_showLevelComplete)
                _pauseOverlay(),

              if (_showTutorial) _tutorialOverlay(),

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
      ),
    );
  }

  // ── Control widgets ─────────────────────────────────────────────────────────

  Widget _dpad() {
    return Row(
      children: [
        _ctrlButton(
          icon: Icons.arrow_left_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.15),
          onPressDown: () => game.touchMove = -1,
          onPressUp: () { if (game.touchMove < 0) game.touchMove = 0; },
        ),
        const SizedBox(width: 10),
        _ctrlButton(
          icon: Icons.arrow_right_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.15),
          onPressDown: () => game.touchMove = 1,
          onPressUp: () { if (game.touchMove > 0) game.touchMove = 0; },
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        _ctrlButton(
          label: 'JUMP',
          size: 70,
          color: AppConstants.bubbleOrange.withValues(alpha: 0.8),
          onPressDown: () => game.touchJump = true,
        ),
        const SizedBox(width: 12),
        _ctrlButton(
          label: 'FIRE',
          size: 70,
          color: AppConstants.bubbleBlue.withValues(alpha: 0.8),
          onPressDown: () => game.touchShoot = true,
        ),
      ],
    );
  }

  void _haptic() {
    if (SaveService.instance.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Widget _ctrlButton({
    IconData? icon,
    String? label,
    double size = 64,
    Color color = Colors.white24,
    VoidCallback? onPressDown,
    VoidCallback? onPressUp,
  }) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _haptic();
        onPressDown?.call();
      },
      onPointerUp: (_) => onPressUp?.call(),
      onPointerCancel: (_) => onPressUp?.call(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Colors.white, size: size * 0.55)
            : Text(
                label ?? '',
                style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    shadows: const [Shadow(color: Colors.black54, blurRadius: 3)]),
              ),
      ),
    );
  }

  Widget _pauseButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 1.5),
        ),
        child: Icon(
          _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ── Pause overlay ───────────────────────────────────────────────────────────

  Widget _pauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x5500E5FF), blurRadius: 24, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '— PAUSED —',
                style: GoogleFonts.fredoka(
                    color: const Color(0xFF00E5FF),
                    fontSize: 32,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 28),
              _menuButton('RESUME', const Color(0xFF00897B), _togglePause),
              const SizedBox(height: 10),
              _menuButton('RESTART', const Color(0xFFFF9800), _restart),
              const SizedBox(height: 10),
              _menuButton('QUIT', const Color(0xFFE53935), () async {
                final quit = await _showQuitDialog();
                if (quit == true) _exit();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: Text(label,
            style: GoogleFonts.fredoka(
                fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Tutorial overlay ────────────────────────────────────────────────────────

  Widget _tutorialOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1520),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFEB3B), width: 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55FFEB3B), blurRadius: 24, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOW TO PLAY',
                style: GoogleFonts.fredoka(
                    color: const Color(0xFFFFEB3B),
                    fontSize: 30,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 20),
              _tutorialRow(Icons.arrow_left_rounded, Icons.arrow_right_rounded,
                  'Move left / right'),
              const SizedBox(height: 14),
              _tutorialRowIcon(AppConstants.bubbleOrange, 'JUMP',
                  'Jump (tap JUMP button)'),
              const SizedBox(height: 14),
              _tutorialRowIcon(AppConstants.bubbleBlue, 'FIRE',
                  'Shoot bubbles to trap enemies'),
              const SizedBox(height: 14),
              _tutorialRowEmoji('👆', 'Tap a trapped bubble to pop it!'),
              const SizedBox(height: 14),
              _tutorialRowEmoji('🎯',
                  'Pop all enemies to clear the level'),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _dismissTutorial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEB3B),
                    foregroundColor: const Color(0xFF0A1520),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  child: Text("LET'S GO!",
                      style: GoogleFonts.fredoka(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tutorialRow(IconData iconL, IconData iconR, String label) {
    return Row(
      children: [
        Icon(iconL, color: Colors.white, size: 28),
        Icon(iconR, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _tutorialRowIcon(Color color, String btnLabel, String desc) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 30,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white54)),
          alignment: Alignment.center,
          child: Text(btnLabel,
              style: GoogleFonts.fredoka(
                  color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(desc,
              style: GoogleFonts.fredoka(
                  color: Colors.white70, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _tutorialRowEmoji(String emoji, String desc) {
    return Row(
      children: [
        SizedBox(
            width: 46,
            child: Text(emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 12),
        Expanded(
          child: Text(desc,
              style: GoogleFonts.fredoka(
                  color: Colors.white70, fontSize: 15)),
        ),
      ],
    );
  }
}
