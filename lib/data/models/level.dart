class Level {
  final int? id;
  final int gameId;
  final int minValue;
  final int maxValue;
  final int digitCount;
  final String difficulty;
  final int unlockScore;

  Level({
    this.id,
    required this.gameId,
    required this.minValue,
    required this.maxValue,
    required this.digitCount,
    required this.difficulty,
    required this.unlockScore,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'game_id': gameId,
        'min_value': minValue,
        'max_value': maxValue,
        'digit_count': digitCount,
        'difficulty': difficulty,
        'unlock_score': unlockScore,
      };

  static Level fromJson(Map<String, dynamic> json) => Level(
        id: json['id'] as int?,
        gameId: json['game_id'] as int,
        minValue: json['min_value'] as int,
        maxValue: json['max_value'] as int,
        digitCount: json['digit_count'] as int,
        difficulty: json['difficulty'] as String,
        unlockScore: json['unlock_score'] as int,
      );
}
