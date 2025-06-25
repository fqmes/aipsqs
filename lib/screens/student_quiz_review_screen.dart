import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentQuizReviewScreen extends StatelessWidget {
  final String docId;

  const StudentQuizReviewScreen({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        centerTitle: true,
        title: const Text(
          "QUIZ REVIEW",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('quizAttempts')
                .doc(docId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Quiz attempt not found.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final questions = List<Map<String, dynamic>>.from(data['questions']);
          final selectedAnswers = List<String>.from(
            data['selectedAnswers'] ?? [],
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final selected =
                  index < selectedAnswers.length
                      ? selectedAnswers[index]
                      : "Not Answered";
              final correct = q['correctAnswer'];

              final isCorrect = selected == correct;

              return Card(
                color: const Color(0xFF3B0C5F),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Q${index + 1}: ${q['question']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Student's Answer: $selected",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Correct Answer: $correct",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCorrect ? "✅ Correct" : "❌ Incorrect",
                        style: TextStyle(
                          color:
                              isCorrect ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
