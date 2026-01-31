class AnswerLog {
  final int? id;
  final int sessionId;
  final String questionText;
  final String givenAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int responseTimeMs;

  AnswerLog({
    this.id,
    required this.sessionId,
    required this.questionText,
    required this.givenAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'question_text': questionText,
        'given_answer': givenAnswer,
        'correct_answer': correctAnswer,
        'is_correct': isCorrect ? 1 : 0,
        'response_time_ms': responseTimeMs,
      };

  static AnswerLog fromJson(Map<String, dynamic> json) => AnswerLog(
        id: json['id'] as int?,
        sessionId: json['session_id'] as int,
        questionText: json['question_text'] as String,
        givenAnswer: json['given_answer'] as String,
        correctAnswer: json['correct_answer'] as String,
        isCorrect: json['is_correct'] == 1,
        responseTimeMs: json['response_time_ms'] as int,
      );
}
