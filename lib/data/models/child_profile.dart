class ChildProfile {
  final int? id;
  final String name;
  final DateTime birthDate;
  final String avatarId;
  final int currentLevel;
  final int totalScore;
  final int lives;
  final DateTime createdAt;

  ChildProfile({
    this.id,
    required this.name,
    required this.birthDate,
    required this.avatarId,
    this.currentLevel = 0,
    this.totalScore = 0,
    this.lives = 5,
    required this.createdAt,
  });

  // Calculate current age from birth date
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birth_date': birthDate.toIso8601String(),
        'avatar_id': avatarId,
        'current_level': currentLevel,
        'total_score': totalScore,
        'lives': lives,
        'created_at': createdAt.toIso8601String(),
      };

  static ChildProfile fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as int?,
        name: json['name'] as String,
        birthDate: DateTime.parse(json['birth_date'] as String),
        avatarId: json['avatar_id'] as String,
        currentLevel: json['current_level'] as int,
        totalScore: json['total_score'] as int,
        lives: (json['lives'] as int?) ?? 5,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ChildProfile copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    String? avatarId,
    int? currentLevel,
    int? totalScore,
    int? lives,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      avatarId: avatarId ?? this.avatarId,
      currentLevel: currentLevel ?? this.currentLevel,
      totalScore: totalScore ?? this.totalScore,
      lives: lives ?? this.lives,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
