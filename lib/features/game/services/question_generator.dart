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
      // TODO: Add implementation for * and / when rules support them
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
