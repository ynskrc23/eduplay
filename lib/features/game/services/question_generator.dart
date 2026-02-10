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
          // Ensure num1 >= num2 for non-negative result
          num2 = _getRandomInt(rule.minOperand, num1); 
        }
        answer = num1 - num2;
        break;
      case '*':
        num1 = _getRandomInt(rule.minOperand, rule.maxOperand);
        // İkinci operandı çok zorlaştırmamak için orta ve zorda bir tık düşük tutuyoruz
        // ama yine de basamak sayısına sadık kalıyoruz
        if (rule.maxOperand >= 100) {
          num2 = _getRandomInt(2, 20); // Zor modda 3 basamak x 1-2 basamak
        } else if (rule.maxOperand >= 10) {
          num2 = _getRandomInt(2, 9);  // Orta modda 2 basamak x 1 basamak
        } else {
          num2 = _getRandomInt(rule.minOperand, rule.maxOperand);
        }
        answer = num1 * num2;
        break;
      case '/':
        {
          // Bölme sonucunun da kurallara uygun olması için tersten gidiyoruz
          if (rule.maxOperand >= 100) { // Zor - 3 basamaklı sayılar
            num2 = _getRandomInt(2, 25);
            int quotient = _getRandomInt(10, 40);
            num1 = num2 * quotient; 
            // Eğer 3 basamaklı değilse zorla
            while (num1 < 100 || num1 > 999) {
              num2 = _getRandomInt(5, 50);
              quotient = _getRandomInt(10, 19);
              num1 = num2 * quotient;
            }
            answer = quotient;
          } else if (rule.maxOperand >= 10) { // Orta - 2 basamaklı sayılar
            num2 = _getRandomInt(2, 9);
            int quotient = _getRandomInt(5, 15);
            num1 = num2 * quotient;
            while (num1 < 10 || num1 > 99) {
               num2 = _getRandomInt(2, 9);
               quotient = _getRandomInt(5, 20);
               num1 = num2 * quotient;
            }
            answer = quotient;
          } else { // Kolay - 1 basamaklı
            num2 = _getRandomInt(1, 5);
            int quotient = _getRandomInt(1, 5);
            num1 = num2 * quotient;
            answer = quotient;
          }
        }
        break;
      default: // Fallback to basic addition
        num1 = _random.nextInt(10);
        num2 = _random.nextInt(10);
        op = '+';
        answer = num1 + num2;
    }

    return Question(num1, num2, op, answer);
  }

  int _getRandomInt(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }
}
