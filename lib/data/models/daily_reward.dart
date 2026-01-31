class DailyReward {
  final int? id;
  final int childId;
  final DateTime rewardDate;
  final String rewardType;
  final int rewardValue;

  DailyReward({
    this.id,
    required this.childId,
    required this.rewardDate,
    required this.rewardType,
    required this.rewardValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'reward_date': rewardDate.toIso8601String(),
        'reward_type': rewardType,
        'reward_value': rewardValue,
      };

  static DailyReward fromJson(Map<String, dynamic> json) => DailyReward(
        id: json['id'] as int?,
        childId: json['child_id'] as int,
        rewardDate: DateTime.parse(json['reward_date'] as String),
        rewardType: json['reward_type'] as String,
        rewardValue: json['reward_value'] as int,
      );
}
