import 'dart:convert';

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;
  final String hint;
  final int points;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    this.hint = '',
    this.points = 100,
  });

  String get correctAnswer => options[correctIndex];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'category': category,
      'hint': hint,
      'points': points,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String,
      question: map['question'] as String,
      options: List<String>.from(map['options'] as List<dynamic>),
      correctIndex: map['correctIndex'] as int,
      explanation: map['explanation'] as String,
      category: map['category'] as String,
      hint: map['hint'] as String? ?? '',
      points: map['points'] as int? ?? 100,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory QuizQuestion.fromJson(String source) =>
      QuizQuestion.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class QuizGameResult {
  final int score;
  final int correctCount;
  final int totalQuestions;
  final String badgeTitle;
  final DateTime playedAt;

  const QuizGameResult({
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.badgeTitle,
    required this.playedAt,
  });

  double get accuracy =>
      totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'badgeTitle': badgeTitle,
      'playedAt': playedAt.toIso8601String(),
    };
  }

  factory QuizGameResult.fromMap(Map<String, dynamic> map) {
    return QuizGameResult(
      score: map['score'] as int? ?? 0,
      correctCount: map['correctCount'] as int? ?? 0,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      badgeTitle: map['badgeTitle'] as String? ?? 'Wisatawan Bandung',
      playedAt: map['playedAt'] != null
          ? DateTime.tryParse(map['playedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
