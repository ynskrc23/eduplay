import 'dart:math';
import '../../../data/models/question_rule.dart';

class Question {
  final int num1;
  final int num2;
  final String operation; // +, -, *, /
  final int answer;

  Question(this.num1, this.num2, this.operation, this.answer);

  @override
  String toString() => '$num1 $operation $num2 = ?';
}

class QuestionGenerator {
  final Random _random = Random();

  Question generate(QuestionRule rule) {
    // Zenginleştirilmiş kurallar varsa onları kullan, yoksa eski basit mantık
    if (_hasRichConstraints(rule)) {
      return _generateRich(rule);
    }
    return _generateBasic(rule);
  }

  bool _hasRichConstraints(QuestionRule rule) {
    return rule.minNum1 != null ||
        rule.maxNum1 != null ||
        rule.minNum2 != null ||
        rule.maxNum2 != null ||
        rule.maxResult != null ||
        rule.minResult != null ||
        rule.multiplicationBases != null;
  }

  // ═══════════════════════════════════════════════════
  // ZENGİN KURAL TABANLı SORU ÜRETİMİ
  // ═══════════════════════════════════════════════════

  Question _generateRich(QuestionRule rule) {
    switch (rule.operation) {
      case '+':
        return _generateRichAddition(rule);
      case '-':
        return _generateRichSubtraction(rule);
      case '*':
        return _generateRichMultiplication(rule);
      case '/':
        return _generateRichDivision(rule);
      default:
        return _generateRichAddition(rule);
    }
  }

  // ── TOPLAMA ──────────────────────────────────────
  Question _generateRichAddition(QuestionRule rule) {
    int minA = rule.minNum1 ?? rule.minOperand;
    int maxA = rule.maxNum1 ?? rule.maxOperand;
    int minB = rule.minNum2 ?? rule.minOperand;
    int maxB = rule.maxNum2 ?? rule.maxOperand;
    int? maxRes = rule.maxResult;
    int? minRes = rule.minResult;

    int num1, num2, answer;
    int attempts = 0;

    do {
      num1 = _getRandomInt(minA, maxA);
      num2 = _getRandomInt(minB, maxB);
      answer = num1 + num2;
      attempts++;
      if (attempts > 200) break;
    } while ((maxRes != null && answer > maxRes) ||
        (minRes != null && answer < minRes));

    return Question(num1, num2, '+', num1 + num2);
  }

  // ── ÇIKARMA ──────────────────────────────────────
  Question _generateRichSubtraction(QuestionRule rule) {
    int minA = rule.minNum1 ?? rule.minOperand;
    int maxA = rule.maxNum1 ?? rule.maxOperand;
    int minB = rule.minNum2 ?? rule.minOperand;
    int maxB = rule.maxNum2 ?? rule.maxOperand;
    int? maxRes = rule.maxResult; // Çıkarmada maxResult: en büyük sayının üst sınırı

    int num1, num2;
    int attempts = 0;

    do {
      num1 = _getRandomInt(minA, maxA);
      num2 = _getRandomInt(minB, maxB);
      // Büyük olan sayıyı num1 yap
      if (num1 < num2) {
        int temp = num1;
        num1 = num2;
        num2 = temp;
      }
      attempts++;
      if (attempts > 200) break;
    } while ((maxRes != null && num1 > maxRes) || num1 == num2);

    int answer = num1 - num2;
    return Question(num1, num2, '-', answer);
  }

  // ── ÇARPMA ──────────────────────────────────────
  Question _generateRichMultiplication(QuestionRule rule) {
    // Çarpım tablosu modu
    if (rule.multiplicationBases != null && rule.multiplicationBases!.isNotEmpty) {
      return _generateMultiplicationTable(rule);
    }
    // Basamak tabanlı mod
    return _generateDigitBasedMultiplication(rule);
  }

  Question _generateMultiplicationTable(QuestionRule rule) {
    final bases = rule.multiplicationBases!;
    int base = bases[_random.nextInt(bases.length)];
    int maxMult = rule.maxMultiplier ?? 10;
    int? maxRes = rule.maxResult;

    int multiplier;
    int result;
    int attempts = 0;

    do {
      multiplier = _getRandomInt(1, maxMult);
      result = base * multiplier;
      attempts++;
      if (attempts > 100) break;
    } while (maxRes != null && result > maxRes);

    // Rastgele sıralama: bazen 3x7, bazen 7x3
    if (_random.nextBool()) {
      return Question(base, multiplier, '*', result);
    } else {
      return Question(multiplier, base, '*', result);
    }
  }

  Question _generateDigitBasedMultiplication(QuestionRule rule) {
    int minA = rule.minNum1 ?? rule.minOperand;
    int maxA = rule.maxNum1 ?? rule.maxOperand;
    int minB = rule.minNum2 ?? rule.minOperand;
    int maxB = rule.maxNum2 ?? rule.maxOperand;
    int? maxRes = rule.maxResult;

    int num1, num2, result;
    int attempts = 0;

    do {
      num1 = _getRandomInt(minA, maxA);
      num2 = _getRandomInt(minB, maxB);
      result = num1 * num2;
      attempts++;
      if (attempts > 200) break;
    } while (maxRes != null && result > maxRes);

    return Question(num1, num2, '*', num1 * num2);
  }

  // ── BÖLME ──────────────────────────────────────
  Question _generateRichDivision(QuestionRule rule) {
    // Çarpım tablosu'nun tersi modu
    if (rule.multiplicationBases != null && rule.multiplicationBases!.isNotEmpty) {
      return _generateDivisionFromTable(rule);
    }
    // Basamak tabanlı kalansız bölme
    return _generateDigitBasedDivision(rule);
  }

  Question _generateDivisionFromTable(QuestionRule rule) {
    final bases = rule.multiplicationBases!;
    int divisor = bases[_random.nextInt(bases.length)];
    int maxMult = rule.maxMultiplier ?? 10;
    int? maxRes = rule.maxResult;

    int quotient;
    int dividend;
    int attempts = 0;

    do {
      quotient = _getRandomInt(1, maxMult);
      dividend = divisor * quotient;
      attempts++;
      if (attempts > 100) break;
    } while (maxRes != null && dividend > maxRes);

    return Question(dividend, divisor, '/', quotient);
  }

  Question _generateDigitBasedDivision(QuestionRule rule) {
    int minA = rule.minNum1 ?? rule.minOperand; // bölünen min
    int maxA = rule.maxNum1 ?? rule.maxOperand; // bölünen max
    int minB = rule.minNum2 ?? 2;               // bölen min
    int maxB = rule.maxNum2 ?? rule.maxOperand;  // bölen max

    int divisor, quotient, dividend;
    int attempts = 0;

    do {
      divisor = _getRandomInt(minB, maxB);
      // Bölümü, bölünenin aralığına göre hesapla
      int minQuotient = max(2, (minA / divisor).ceil());
      int maxQuotient = (maxA / divisor).floor();
      if (maxQuotient < minQuotient) maxQuotient = minQuotient;

      quotient = _getRandomInt(minQuotient, maxQuotient);
      dividend = divisor * quotient;
      attempts++;
      if (attempts > 200) break;
    } while (dividend < minA || dividend > maxA);

    return Question(dividend, divisor, '/', quotient);
  }

  // ═══════════════════════════════════════════════════
  // ESKİ BASİT KURAL TABANLı SORU ÜRETİMİ
  // (Veritabanından gelen level kuralları için)
  // ═══════════════════════════════════════════════════

  Question _generateBasic(QuestionRule rule) {
    int num1, num2, answer;
    String op = rule.operation;

    switch (op) {
      case '+':
        num1 = _getRandomInt(rule.minOperand, rule.maxOperand);
        num2 = _getRandomInt(rule.minOperand, rule.maxOperand);
        answer = num1 + num2;
        break;
      case '-':
        num1 = _getRandomInt(rule.minOperand, rule.maxOperand);
        if (rule.allowNegative) {
          num2 = _getRandomInt(rule.minOperand, rule.maxOperand);
        } else {
          num2 = _getRandomInt(rule.minOperand, num1);
        }
        answer = num1 - num2;
        break;
      case '*':
        num1 = _getRandomInt(rule.minOperand, rule.maxOperand);
        if (rule.maxOperand >= 100) {
          num2 = _getRandomInt(2, 20);
        } else if (rule.maxOperand >= 10) {
          num2 = _getRandomInt(2, 9);
        } else {
          num2 = _getRandomInt(rule.minOperand, rule.maxOperand);
        }
        answer = num1 * num2;
        break;
      case '/':
        {
          if (rule.maxOperand >= 100) {
            num2 = _getRandomInt(2, 25);
            int quotient = _getRandomInt(10, 40);
            num1 = num2 * quotient;
            while (num1 < 100 || num1 > 999) {
              num2 = _getRandomInt(5, 50);
              quotient = _getRandomInt(10, 19);
              num1 = num2 * quotient;
            }
            answer = quotient;
          } else if (rule.maxOperand >= 10) {
            num2 = _getRandomInt(2, 9);
            int quotient = _getRandomInt(5, 15);
            num1 = num2 * quotient;
            while (num1 < 10 || num1 > 99) {
              num2 = _getRandomInt(2, 9);
              quotient = _getRandomInt(5, 20);
              num1 = num2 * quotient;
            }
            answer = quotient;
          } else {
            num2 = _getRandomInt(1, 5);
            int quotient = _getRandomInt(1, 5);
            num1 = num2 * quotient;
            answer = quotient;
          }
        }
        break;
      default:
        num1 = _random.nextInt(10);
        num2 = _random.nextInt(10);
        op = '+';
        answer = num1 + num2;
    }

    return Question(num1, num2, op, answer);
  }

  // ═══════════════════════════════════════════════════
  // AKILLI ŞIK ÜRETİMİ
  // ═══════════════════════════════════════════════════

  List<int> generateOptions(Question question, int count) {
    Set<int> options = {question.answer};

    // 1. Strateji: Cevap 2 basamaklı ve üzeri ise (ve bölme değilse)
    // son basamağı aynı olan yakın bir yanıltıcı ekle (Örn: 120 -> 130 veya 110)
    if (question.answer >= 10 && question.operation != '/') {
      int offset = 10;
      int wrong = _random.nextBool() ? question.answer + offset : question.answer - offset;

      if (wrong > 0 && !options.contains(wrong)) {
        options.add(wrong);
      }
    }

    // 2. Geri kalan şıkları birbirine çok yakın (+/- 10 aralığında) sayılardan tamamla
    int attempts = 0;
    while (options.length < count && attempts < 50) {
      attempts++;
      int offset = _random.nextInt(21) - 10;
      if (offset == 0) continue;

      int wrong = question.answer + offset;
      if (wrong > 0 && !options.contains(wrong)) {
        options.add(wrong);
      }
    }

    // Nadir durumlarda hala dolmadıysa sıralı ekle
    for (int i = 1; options.length < count; i++) {
      int nextWrong = (question.answer + i > 0) ? question.answer + i : question.answer - i;
      options.add(nextWrong);
    }

    List<int> result = options.toList();
    result.shuffle();
    return result;
  }

  int _getRandomInt(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }
}
