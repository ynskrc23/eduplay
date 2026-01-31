class GameSession {
  final int? id;
  final int childId;
  final int gameId;
  final int levelId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;

  GameSession({
    this.id,
    required this.childId,
    required this.gameId,
    required this.levelId,
    required this.startedAt,
    this.endedAt,
    this.totalQuestions = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'game_id': gameId,
        'level_id': levelId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'total_questions': totalQuestions,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
      };

  static GameSession fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as int?,
        childId: json['child_id'] as int,
        gameId: json['game_id'] as int,
        levelId: json['level_id'] as int,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
        totalQuestions: json['total_questions'] as int,
        correctCount: json['correct_count'] as int,
        wrongCount: json['wrong_count'] as int,
      );
}
