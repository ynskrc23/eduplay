class ChildProfile {
  final int? id;
  final String name;
  final int age;
  final String avatarId;
  final int currentLevel;
  final int totalScore;
  final DateTime createdAt;

  ChildProfile({
    this.id,
    required this.name,
    required this.age,
    required this.avatarId,
    this.currentLevel = 1,
    this.totalScore = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'avatar_id': avatarId,
        'current_level': currentLevel,
        'total_score': totalScore,
        'created_at': createdAt.toIso8601String(),
      };

  static ChildProfile fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as int?,
        name: json['name'] as String,
        age: json['age'] as int,
        avatarId: json['avatar_id'] as String,
        currentLevel: json['current_level'] as int,
        totalScore: json['total_score'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ChildProfile copyWith({
    int? id,
    String? name,
    int? age,
    String? avatarId,
    int? currentLevel,
    int? totalScore,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarId: avatarId ?? this.avatarId,
      currentLevel: currentLevel ?? this.currentLevel,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
