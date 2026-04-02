import '../../../data/models/question_rule.dart';

class DifficultyService {
  static List<QuestionRule> getRules(int age, String operation, String difficulty) {
    if (age <= 5) {
      return _getPreSchoolRules(operation, difficulty);
    } else if (age <= 8) {
      return _getEarlyPrimaryRules(operation, difficulty);
    } else if (age <= 11) {
      return _getLatePrimaryRules(operation, difficulty);
    } else {
      return _getMiddleSchoolRules(operation, difficulty);
    }
  }

  // 3-5 Yaş: Okul Öncesi (Çok Basit)
  static List<QuestionRule> _getPreSchoolRules(String op, String diff) {
    int min = 1;
    int max = 5;

    switch (diff) {
      case 'kolay':
        max = 5;
        break;
      case 'orta':
        max = 10;
        break;
      case 'zor':
        max = 15;
        break;
    }

    // Çarpma ve bölme için operandları daha da küçültelim (Örn: 2x2, 6/2)
    if (op == '*' || op == '/') {
      max = (diff == 'kolay') ? 3 : (diff == 'orta' ? 5 : 8);
    }

    return [
      QuestionRule(
        levelId: 0,
        operation: op,
        minOperand: min,
        maxOperand: max,
        allowNegative: false,
      )
    ];
  }

  // 6-8 Yaş: İlkokul 1-2
  static List<QuestionRule> _getEarlyPrimaryRules(String op, String diff) {
    int min = 1;
    int max = 10;

    if (op == '+' || op == '-') {
      switch (diff) {
        case 'kolay': max = 20; break;
        case 'orta': max = 50; break;
        case 'zor': max = 100; break;
      }
    } else { // Çarpma / Bölme
      switch (diff) {
        case 'kolay': max = 5; break;
        case 'orta': max = 10; break;
        case 'zor': max = 12; break;
      }
    }

    return [
      QuestionRule(
        levelId: 0,
        operation: op,
        minOperand: min,
        maxOperand: max,
        allowNegative: false,
      )
    ];
  }

  // 9-11 Yaş: İlkokul 3-4
  static List<QuestionRule> _getLatePrimaryRules(String op, String diff) {
    int min = 1;
    int max = 20;

    if (op == '+' || op == '-') {
      switch (diff) {
        case 'kolay': max = 100; break;
        case 'orta': max = 500; break;
        case 'zor': max = 1000; break;
      }
    } else { // Çarpma / Bölme
      switch (diff) {
        case 'kolay': max = 12; break; // Çarpım tablosu
        case 'orta': max = 50; break; // 2 basamak x 1 basamak
        case 'zor': max = 100; break; // 2 basamak x 2 basamak
      }
    }

    return [
      QuestionRule(
        levelId: 0,
        operation: op,
        minOperand: min,
        maxOperand: max,
        allowNegative: false,
      )
    ];
  }

  // 12+ Yaş: Ortaokul ve üzeri
  static List<QuestionRule> _getMiddleSchoolRules(String op, String diff) {
    int min = 10;
    int max = 100;

    if (op == '+' || op == '-') {
      switch (diff) {
        case 'kolay': max = 1000; break;
        case 'orta': max = 5000; break;
        case 'zor': max = 10000; break;
      }
    } else { // Çarpma / Bölme
      switch (diff) {
        case 'kolay': max = 100; break;
        case 'orta': max = 500; break;
        case 'zor': max = 1000; break;
      }
    }

    return [
      QuestionRule(
        levelId: 0,
        operation: op,
        minOperand: min,
        maxOperand: max,
        allowNegative: (diff == 'zor'), // Sadece zor modda negatife izin ver
      )
    ];
  }
}
