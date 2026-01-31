class ChildAchievement {
  final int? id;
  final int childId;
  final int achievementId;
  final DateTime earnedAt;

  ChildAchievement({
    this.id,
    required this.childId,
    required this.achievementId,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'achievement_id': achievementId,
        'earned_at': earnedAt.toIso8601String(),
      };

  static ChildAchievement fromJson(Map<String, dynamic> json) => ChildAchievement(
        id: json['id'] as int?,
        childId: json['child_id'] as int,
        achievementId: json['achievement_id'] as int,
        earnedAt: DateTime.parse(json['earned_at'] as String),
      );
}
