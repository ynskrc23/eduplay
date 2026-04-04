class QuestionRule {
  final int? id;
  final int levelId;
  final String operation;
  final int minOperand;
  final int maxOperand;
  final bool allowNegative;

  // Runtime-only fields (NOT stored in DB)
  final int? maxResult;       // Sonucun üst sınırı (Örn: toplam 25'i geçmesin)
  final int? minResult;       // Sonucun alt sınırı (Örn: toplam en az 100 olsun)
  final int? minNum1;         // İlk sayının min değeri
  final int? maxNum1;         // İlk sayının max değeri
  final int? minNum2;         // İkinci sayının min değeri
  final int? maxNum2;         // İkinci sayının max değeri
  final List<int>? multiplicationBases; // Belirli çarpım tabloları (Örn: [4, 5, 6])
  final int? maxMultiplier;   // Çarpımda çarpanın üst sınırı (Örn: 10'a kadar)

  QuestionRule({
    this.id,
    required this.levelId,
    required this.operation,
    required this.minOperand,
    required this.maxOperand,
    required this.allowNegative,
    this.maxResult,
    this.minResult,
    this.minNum1,
    this.maxNum1,
    this.minNum2,
    this.maxNum2,
    this.multiplicationBases,
    this.maxMultiplier,
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
