import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/ai_quiz.dart';

class QuizController extends ChangeNotifier {
  final WorkersAI aiService;
  List<QuizItem> _questions = [];
  Map<int, String> _userAnswers = {};
  bool _isLoading = false;

  QuizController(this.aiService);

  List<QuizItem> get questions => _questions;
  Map<int, String> get userAnswers => _userAnswers;
  bool get isLoading => _isLoading;

  Future<void> loadQuiz(String topic, String difficulty, int number) async {
    _isLoading = true;
    notifyListeners();

    try {
      final rawQuestions = await aiService.generateQuiz(
        topic,
        difficulty,
        number,
      );

      _questions =
          rawQuestions
              .map((data) {
                try {
                  return QuizItem.fromMap(data);
                } catch (e) {
                  print("⚠️ Skipped malformed quiz item: $data");
                  return null;
                }
              })
              .whereType<QuizItem>()
              .toList();

      _userAnswers = {};
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(int index, String answer) {
    _userAnswers[index] = answer;
    notifyListeners();
  }

  int calculateScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctAnswer) {
        score++;
      }
    }
    return score;
  }

  void reset() {
    _questions = [];
    _userAnswers = {};
    notifyListeners();
  }
}
