import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/user_quizzes.dart';
import 'feedback_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String teacherId;
  final bool saveToHistory;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.teacherId,
    this.saveToHistory = true,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final quizService = UserQuizzes();
  List<QuizItem> _questions = [];
  final Map<int, String> _userAnswers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      if (widget.teacherId == "ai_quiz") {
        _questions = widget.quiz.questions;
        setState(() => _loading = false);
      } else {
        final items = await quizService.getQuizItems(
          widget.quiz.docId,
          widget.teacherId,
        );
        if (!mounted) return;
        setState(() {
          _questions = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading quiz: $e")));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    // Check if all questions are answered
    if (_userAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions before submitting."),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
        ),
      );
      return;
    }

    final score =
        _questions.where((q) {
          final index = _questions.indexOf(q);
          return _userAnswers[index] == q.correctAnswer;
        }).length;

    try {
      if (widget.teacherId == "ai_quiz" && widget.saveToHistory) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final now = DateTime.now();
          await FirebaseFirestore.instance.collection('quizAttempts').add({
            'userId': user.uid,
            'submittedAt': now,
            'source': 'ai',
            'prompt': widget.quiz.prompt,
            'questions':
                _questions
                    .map(
                      (q) => {
                        'question': q.question,
                        'options': q.options,
                        'correctAnswer': q.correctAnswer,
                        'id': q.id,
                      },
                    )
                    .toList(),
            'selectedAnswers': List.generate(
              _questions.length,
              (index) => _userAnswers[index] ?? "",
            ),
          });
        }
      } else {
        await quizService.submitScore(
          widget.quiz.docId,
          score,
          widget.teacherId,
        );
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FeedbackScreen(
                questions: _questions,
                userAnswers: _userAnswers,
                score: score,
              ),
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error submitting quiz: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        title: const Text(
          "GOOD LUCK!",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB300),
      ),
      body:
          _questions.isEmpty
              ? const Center(
                child: Text(
                  "No questions found for this quiz.",
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...List.generate(_questions.length, (i) {
                    final q = _questions[i];
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
                            const SizedBox(height: 8),
                            ...q.options.map(
                              (opt) => RadioListTile<String>(
                                value: opt,
                                groupValue: _userAnswers[i],
                                onChanged:
                                    (val) =>
                                        setState(() => _userAnswers[i] = val!),
                                title: Text(
                                  opt,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                activeColor: const Color(0xFFFFB300),
                                tileColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Submit Quiz",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
    );
  }
}
