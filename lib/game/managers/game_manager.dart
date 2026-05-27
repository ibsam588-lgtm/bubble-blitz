import 'package:flutter/foundation.dart';

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
