enum CharacterType { dragon, phoenix, shadow }

extension CharacterTypeX on CharacterType {
  String get displayName {
    switch (this) {
      case CharacterType.dragon:
        return 'Green Dino';
      case CharacterType.phoenix:
        return 'Red Dino';
      case CharacterType.shadow:
        return 'Blue Dino';
    }
  }

  String get id {
    switch (this) {
      case CharacterType.dragon:
        return 'dragon';
      case CharacterType.phoenix:
        return 'phoenix';
      case CharacterType.shadow:
        return 'shadow';
    }
  }

  String get emoji {
    switch (this) {
      case CharacterType.dragon:
        return 'G';
      case CharacterType.phoenix:
        return 'R';
      case CharacterType.shadow:
        return 'B';
    }
  }
}

class PlayerData {
  int coins;
  int highScore;
  List<String> unlockedChars;
  String selectedChar;
  int unlockedLevels;
  Map<int, int> levelStars;
  int shields;
  int speedBoosts;
  int multiBubbles;
  int extraLives;

  PlayerData({
    this.coins = 0,
    this.highScore = 0,
    List<String>? unlockedChars,
    this.selectedChar = 'dragon',
    this.unlockedLevels = 1,
    Map<int, int>? levelStars,
    this.shields = 0,
    this.speedBoosts = 0,
    this.multiBubbles = 0,
    this.extraLives = 0,
  })  : unlockedChars = unlockedChars ?? ['dragon'],
        levelStars = levelStars ?? {};
}
