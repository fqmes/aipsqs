import 'package:flutter/material.dart';
import '../models/quiz.dart';

class FeedbackScreen extends StatelessWidget {
  final List<QuizItem> questions;
  final Map<int, String> userAnswers;
  final int score;

  const FeedbackScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        centerTitle: true,
        title: const Text(
          "RESULTS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, i) {
          final q = questions[i];
          final userAnswer = userAnswers[i] ?? 'N/A';
          final correct = userAnswer == q.correctAnswer;

          return Card(
            color: const Color(0xFF3B0C5F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${i + 1}: ${q.question}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your Answer: $userAnswer",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "Correct Answer: ${q.correctAnswer}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correct ? "✅ Correct" : "❌ Incorrect",
                    style: TextStyle(
                      color: correct ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1F0033),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Score: $score / ${questions.length}",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
