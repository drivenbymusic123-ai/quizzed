import 'dart:convert';

enum QuestionType { multipleChoice, trueFalse, shortAnswer }

class Question {
  final String questionText;
  final QuestionType type;
  final List<String> options; // empty for trueFalse / shortAnswer
  final String answer; // correct answer (for trueFalse: "True" or "False")

  Question({
    required this.questionText,
    required this.type,
    this.options = const [],
    required this.answer,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'type': type.index,
      'options': options,
      'answer': answer,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['questionText'] as String,
      type: QuestionType.values[map['type'] as int],
      options: List<String>.from(map['options'] ?? []),
      answer: map['answer'] as String,
    );
  }
}

class Quiz {
  final String id; // generated secret code
  final String title;
  final String description;
  final List<Question> questions;
  final bool isOnline;
  final bool liveSync;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.isOnline,
    required this.liveSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isOnline': isOnline,
      'liveSync': liveSync,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      isOnline: map['isOnline'] as bool,
      liveSync: map['liveSync'] as bool,
      questions: List<dynamic>.from(map['questions'] ?? []).
          map((q) => Question.fromMap(q as Map<String, dynamic>)).toList(),
    );
  }

  String toJson() => jsonEncode(toMap());
  static Quiz fromJson(String source) => Quiz.fromMap(jsonDecode(source));
}
