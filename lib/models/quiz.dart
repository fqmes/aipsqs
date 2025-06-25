class Quiz {
  final dynamic docId;
  final String difficulty;
  final int number;
  final String prompt;
  final List<QuizItem> questions;

  Quiz({
    required this.docId,
    required this.difficulty,
    required this.number,
    required this.prompt,
    required this.questions,
  });

  factory Quiz.fromMap(Map<String, dynamic> data, dynamic docId) {
    return Quiz(
      docId: docId,
      difficulty: data['difficulty'],
      number: int.parse(data['number'].toString()),
      prompt: data['prompt'],
      questions:
          (data['questions'] != null)
              ? (data['questions'] as List)
                  .map((q) => QuizItem.fromMap(q))
                  .toList()
              : [],
    );
  }
}

class QuizItem {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;

  QuizItem({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizItem.fromMap(Map<String, dynamic> data) {
    return QuizItem(
      id: data['id'] ?? '',
      question: data['question'],
      options: List<String>.from(data['options']),
      correctAnswer: data['answer'],
    );
  }
}
