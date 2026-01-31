class QuestionRule {
  final int? id;
  final int levelId;
  final String operation;
  final int minOperand;
  final int maxOperand;
  final bool allowNegative;

  QuestionRule({
    this.id,
    required this.levelId,
    required this.operation,
    required this.minOperand,
    required this.maxOperand,
    required this.allowNegative,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'level_id': levelId,
        'operation': operation,
        'min_operand': minOperand,
        'max_operand': maxOperand,
        'allow_negative': allowNegative ? 1 : 0,
      };

  static QuestionRule fromJson(Map<String, dynamic> json) => QuestionRule(
        id: json['id'] as int?,
        levelId: json['level_id'] as int,
        operation: json['operation'] as String,
        minOperand: json['min_operand'] as int,
        maxOperand: json['max_operand'] as int,
        allowNegative: json['allow_negative'] == 1,
      );
}
