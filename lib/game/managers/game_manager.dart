import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/player_data.dart';
import '../../services/save_service.dart';

class GameManager extends ChangeNotifier {
  int score = 0;
  int coinsCollected = 0;
  int lives = 3;
  int currentLevel = 1;
  bool isPaused = false;
  bool isGameOver = false;
  bool isLevelComplete = false;

  // Power-up counters available this run
  int multiBubbleShots = 0;
  bool bigBubbleActive = false;
  double bigBubbleTimer = 0;

  void reset(int level) {
    score = 0;
    coinsCollected = 0;
    lives = 3 + SaveService.instance.data.extraLives;
    currentLevel = level;
    isPaused = false;
    isGameOver = false;
    isLevelComplete = false;
    multiBubbleShots = SaveService.instance.data.multiBubbles;
    bigBubbleActive = false;
    bigBubbleTimer = 0;
    notifyListeners();
  }

  void addScore(int v) {
    score += v;
    notifyListeners();
  }

  void addCoin() {
    coinsCollected += 1;
    score += 10;
    notifyListeners();
  }

  void loseLife() {
    lives -= 1;
    if (lives <= 0) {
      isGameOver = true;
    }
    notifyListeners();
  }

  void revive() {
    lives = 1;
    isGameOver = false;
    notifyListeners();
  }

  void completeLevel() {
    isLevelComplete = true;
    notifyListeners();
  }

  int starsEarned() {
    if (coinsCollected >= 15) return 3;
    if (coinsCollected >= 8) return 2;
    return 1;
  }

  void useMultiBubble() {
    if (multiBubbleShots > 0) multiBubbleShots -= 1;
    notifyListeners();
  }

  void activateBigBubble() {
    bigBubbleActive = true;
    bigBubbleTimer = 10.0;
    notifyListeners();
  }

  /// High score from persistent storage.
  int get hiScore => SaveService.instance.data.highScore;

  /// Body color of the currently selected player character.
  Color get playerCharColor {
    final id = SaveService.instance.data.selectedChar;
    switch (id) {
      case 'phoenix': return const Color(0xFF00B8D9);
      case 'shadow':  return const Color(0xFFE91E8C);
      default:        return const Color(0xFF2EC05C); // dragon
    }
  }

  void tickPowerups(double dt) {
    if (bigBubbleActive) {
      bigBubbleTimer -= dt;
      if (bigBubbleTimer <= 0) {
        bigBubbleActive = false;
        notifyListeners();
      }
    }
  }
}
