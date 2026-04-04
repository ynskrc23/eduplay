import '../../../data/models/question_rule.dart';

class DifficultyService {
  static List<QuestionRule> getRules(int age, String operation, String difficulty) {
    if (age <= 5) {
      return _preSchool(operation, difficulty);
    } else if (age <= 8) {
      return _earlyPrimary(operation, difficulty);
    } else if (age <= 11) {
      return _latePrimary(operation, difficulty);
    } else {
      return _middleSchool(operation, difficulty);
    }
  }

  // ═══════════════════════════════════════════════════
  // 3-5 YAŞ: OKUL ÖNCESİ
  // ═══════════════════════════════════════════════════

  static List<QuestionRule> _preSchool(String op, String diff) {
    switch (op) {
      case '+': return _preSchoolAdd(diff);
      case '-': return _preSchoolSub(diff);
      case '*': return _preSchoolMul(diff);
      case '/': return _preSchoolDiv(diff);
      default: return _preSchoolAdd(diff);
    }
  }

  static List<QuestionRule> _preSchoolAdd(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 9,
            minNum1: 1, maxNum1: 9, minNum2: 1, maxNum2: 9, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 25,
            minNum1: 1, maxNum1: 9, minNum2: 10, maxNum2: 20, maxResult: 25, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 40,
            minNum1: 1, maxNum1: 9, minNum2: 10, maxNum2: 35, maxResult: 40, allowNegative: false),
          QuestionRule(levelId: 0, operation: '+', minOperand: 10, maxOperand: 30,
            minNum1: 10, maxNum1: 25, minNum2: 10, maxNum2: 25, maxResult: 40, allowNegative: false),
        ];
      default: return _preSchoolAdd('kolay');
    }
  }

  static List<QuestionRule> _preSchoolSub(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 9,
            minNum1: 1, maxNum1: 9, minNum2: 1, maxNum2: 9, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 25,
            minNum1: 10, maxNum1: 25, minNum2: 1, maxNum2: 9, maxResult: 25, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 40,
            minNum1: 10, maxNum1: 40, minNum2: 1, maxNum2: 9, maxResult: 40, allowNegative: false),
          QuestionRule(levelId: 0, operation: '-', minOperand: 10, maxOperand: 40,
            minNum1: 10, maxNum1: 40, minNum2: 10, maxNum2: 35, maxResult: 40, allowNegative: false),
        ];
      default: return _preSchoolSub('kolay');
    }
  }

  static List<QuestionRule> _preSchoolMul(String diff) {
    return [
      QuestionRule(levelId: 0, operation: '*', minOperand: 1, maxOperand: 5,
        multiplicationBases: [1, 2, 3], maxMultiplier: 5, allowNegative: false),
    ];
  }

  static List<QuestionRule> _preSchoolDiv(String diff) {
    return [
      QuestionRule(levelId: 0, operation: '/', minOperand: 1, maxOperand: 5,
        multiplicationBases: [1, 2, 3], maxMultiplier: 5, allowNegative: false),
    ];
  }

  // ═══════════════════════════════════════════════════
  // 6-8 YAŞ: İLKOKUL 1-2
  // ═══════════════════════════════════════════════════

  static List<QuestionRule> _earlyPrimary(String op, String diff) {
    switch (op) {
      case '+': return _earlyPrimaryAdd(diff);
      case '-': return _earlyPrimarySub(diff);
      case '*': return _earlyPrimaryMul(diff);
      case '/': return _earlyPrimaryDiv(diff);
      default: return _earlyPrimaryAdd(diff);
    }
  }

  static List<QuestionRule> _earlyPrimaryAdd(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 9,
            minNum1: 1, maxNum1: 9, minNum2: 1, maxNum2: 9, maxResult: 25, allowNegative: false),
          QuestionRule(levelId: 0, operation: '+', minOperand: 10, maxOperand: 15,
            minNum1: 10, maxNum1: 15, minNum2: 10, maxNum2: 15, maxResult: 25, allowNegative: false),
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 20,
            minNum1: 1, maxNum1: 9, minNum2: 10, maxNum2: 20, maxResult: 25, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1, maxOperand: 99,
            minNum1: 10, maxNum1: 90, minNum2: 1, maxNum2: 90, maxResult: 100, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 10, maxOperand: 199,
            minNum1: 10, maxNum1: 150, minNum2: 10, maxNum2: 150, maxResult: 200, allowNegative: false),
        ];
      default: return _earlyPrimaryAdd('kolay');
    }
  }

  static List<QuestionRule> _earlyPrimarySub(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 9,
            minNum1: 1, maxNum1: 9, minNum2: 1, maxNum2: 9, maxResult: 25, allowNegative: false),
          QuestionRule(levelId: 0, operation: '-', minOperand: 10, maxOperand: 25,
            minNum1: 10, maxNum1: 25, minNum2: 10, maxNum2: 25, maxResult: 25, allowNegative: false),
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 25,
            minNum1: 10, maxNum1: 25, minNum2: 1, maxNum2: 9, maxResult: 25, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 100,
            minNum1: 10, maxNum1: 100, minNum2: 1, maxNum2: 90, maxResult: 100, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 1, maxOperand: 200,
            minNum1: 20, maxNum1: 200, minNum2: 10, maxNum2: 150, maxResult: 200, allowNegative: false),
        ];
      default: return _earlyPrimarySub('kolay');
    }
  }

  static List<QuestionRule> _earlyPrimaryMul(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 1, maxOperand: 30,
            multiplicationBases: [1, 2, 3], maxMultiplier: 10, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 1, maxOperand: 60,
            multiplicationBases: [4, 5, 6], maxMultiplier: 10, maxResult: 60, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 1, maxOperand: 100,
            multiplicationBases: [7, 8, 9, 10], maxMultiplier: 10, maxResult: 100, allowNegative: false),
        ];
      default: return _earlyPrimaryMul('kolay');
    }
  }

  static List<QuestionRule> _earlyPrimaryDiv(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 1, maxOperand: 30,
            multiplicationBases: [1, 2, 3], maxMultiplier: 10, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 1, maxOperand: 60,
            multiplicationBases: [4, 5, 6], maxMultiplier: 10, maxResult: 60, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 1, maxOperand: 100,
            multiplicationBases: [7, 8, 9, 10], maxMultiplier: 10, maxResult: 100, allowNegative: false),
        ];
      default: return _earlyPrimaryDiv('kolay');
    }
  }

  // ═══════════════════════════════════════════════════
  // 9-11 YAŞ: İLKOKUL 3-4
  // ═══════════════════════════════════════════════════

  static List<QuestionRule> _latePrimary(String op, String diff) {
    switch (op) {
      case '+': return _latePrimaryAdd(diff);
      case '-': return _latePrimarySub(diff);
      case '*': return _latePrimaryMul(diff);
      case '/': return _latePrimaryDiv(diff);
      default: return _latePrimaryAdd(diff);
    }
  }

  static List<QuestionRule> _latePrimaryAdd(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 10, maxOperand: 900,
            minNum1: 10, maxNum1: 900, minNum2: 10, maxNum2: 500,
            minResult: 100, maxResult: 1000, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 100, maxOperand: 4000,
            minNum1: 100, maxNum1: 4000, minNum2: 100, maxNum2: 3000,
            minResult: 1000, maxResult: 5000, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 500, maxOperand: 9000,
            minNum1: 500, maxNum1: 8000, minNum2: 500, maxNum2: 5000,
            minResult: 5000, maxResult: 10000, allowNegative: false),
        ];
      default: return _latePrimaryAdd('kolay');
    }
  }

  static List<QuestionRule> _latePrimarySub(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 10, maxOperand: 999,
            minNum1: 100, maxNum1: 999, minNum2: 10, maxNum2: 500,
            maxResult: 999, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 100, maxOperand: 5000,
            minNum1: 500, maxNum1: 5000, minNum2: 100, maxNum2: 3000,
            maxResult: 5000, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 100, maxOperand: 9999,
            minNum1: 1000, maxNum1: 9999, minNum2: 100, maxNum2: 5000,
            maxResult: 9999, allowNegative: false),
        ];
      default: return _latePrimarySub('kolay');
    }
  }

  static List<QuestionRule> _latePrimaryMul(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 7, maxOperand: 100,
            multiplicationBases: [7, 8, 9, 10], maxMultiplier: 10,
            maxResult: 200, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 2, maxOperand: 99,
            minNum1: 2, maxNum1: 9, minNum2: 10, maxNum2: 99,
            maxResult: 8000, allowNegative: false),
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 10, maxNum2: 99,
            maxResult: 8000, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 999,
            minNum1: 10, maxNum1: 99, minNum2: 100, maxNum2: 999,
            maxResult: 60000, allowNegative: false),
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 10, maxNum2: 99,
            maxResult: 60000, allowNegative: false),
        ];
      default: return _latePrimaryMul('kolay');
    }
  }

  static List<QuestionRule> _latePrimaryDiv(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 2, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 2, maxNum2: 9, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 2, maxOperand: 999,
            minNum1: 100, maxNum1: 999, minNum2: 2, maxNum2: 99, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 10, maxOperand: 9999,
            minNum1: 1000, maxNum1: 9999, minNum2: 10, maxNum2: 999, allowNegative: false),
        ];
      default: return _latePrimaryDiv('kolay');
    }
  }

  // ═══════════════════════════════════════════════════
  // 12+ YAŞ: ORTAOKUL
  // ═══════════════════════════════════════════════════

  static List<QuestionRule> _middleSchool(String op, String diff) {
    switch (op) {
      case '+': return _middleSchoolAdd(diff);
      case '-': return _middleSchoolSub(diff);
      case '*': return _middleSchoolMul(diff);
      case '/': return _middleSchoolDiv(diff);
      default: return _middleSchoolAdd(diff);
    }
  }

  static List<QuestionRule> _middleSchoolAdd(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 100, maxOperand: 9999,
            minNum1: 100, maxNum1: 9999, minNum2: 100, maxNum2: 9999, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1000, maxOperand: 9999,
            minNum1: 1000, maxNum1: 9999, minNum2: 1000, maxNum2: 9999, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '+', minOperand: 1000, maxOperand: 99999,
            minNum1: 1000, maxNum1: 99999, minNum2: 1000, maxNum2: 99999, allowNegative: false),
        ];
      default: return _middleSchoolAdd('kolay');
    }
  }

  static List<QuestionRule> _middleSchoolSub(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 10, maxOperand: 4999,
            minNum1: 100, maxNum1: 4999, minNum2: 10, maxNum2: 2000,
            maxResult: 4999, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 100, maxOperand: 50000,
            minNum1: 1000, maxNum1: 50000, minNum2: 100, maxNum2: 25000,
            maxResult: 50000, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '-', minOperand: 100, maxOperand: 99999,
            minNum1: 5000, maxNum1: 99999, minNum2: 100, maxNum2: 50000,
            maxResult: 99999, allowNegative: false),
        ];
      default: return _middleSchoolSub('kolay');
    }
  }

  static List<QuestionRule> _middleSchoolMul(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 2, maxOperand: 99,
            minNum1: 2, maxNum1: 9, minNum2: 10, maxNum2: 99,
            maxResult: 10000, allowNegative: false),
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 10, maxNum2: 99,
            maxResult: 10000, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 999,
            minNum1: 10, maxNum1: 99, minNum2: 100, maxNum2: 999,
            maxResult: 90000, allowNegative: false),
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 10, maxNum2: 99,
            maxResult: 90000, allowNegative: false),
        ];
      case 'zor':
        return [
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 999,
            minNum1: 10, maxNum1: 99, minNum2: 100, maxNum2: 999,
            maxResult: 99000, allowNegative: false),
          QuestionRule(levelId: 0, operation: '*', minOperand: 10, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 10, maxNum2: 99,
            maxResult: 99000, allowNegative: false),
        ];
      default: return _middleSchoolMul('kolay');
    }
  }

  static List<QuestionRule> _middleSchoolDiv(String diff) {
    switch (diff) {
      case 'kolay':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 2, maxOperand: 99,
            minNum1: 10, maxNum1: 99, minNum2: 2, maxNum2: 9, allowNegative: false),
          QuestionRule(levelId: 0, operation: '/', minOperand: 2, maxOperand: 999,
            minNum1: 100, maxNum1: 999, minNum2: 2, maxNum2: 99, allowNegative: false),
        ];
      case 'orta':
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 10, maxOperand: 9999,
            minNum1: 1000, maxNum1: 9999, minNum2: 10, maxNum2: 999, allowNegative: false),
        ];
      case 'zor':
        // 5 basamaklı ÷ (2, 3 veya 4 basamaklı), kalansız
        return [
          QuestionRule(levelId: 0, operation: '/', minOperand: 10, maxOperand: 99999,
            minNum1: 10000, maxNum1: 99999, minNum2: 10, maxNum2: 9999, allowNegative: false),
        ];
      default: return _middleSchoolDiv('kolay');
    }
  }
}
