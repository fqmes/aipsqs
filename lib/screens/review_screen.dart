// At the top of your file:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'quiz_screen.dart';
import '../models/quiz.dart';
import '../services/ai_quiz.dart';

class ReviewScreen extends StatefulWidget {
  final WorkersAI aiService;

  const ReviewScreen({super.key, required this.aiService});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<DocumentSnapshot> _allAttempts = [];
  List<DocumentSnapshot> _filteredAttempts = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('quizAttempts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('submittedAt', descending: true)
            .get();

    setState(() {
      _allAttempts = snapshot.docs;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      if (_filter == 'All') {
        _filteredAttempts = _allAttempts;
      } else {
        final source = _filter == 'Made' ? 'ai' : 'teacher';
        _filteredAttempts =
            _allAttempts
                .where(
                  (doc) =>
                      (doc.data() as Map<String, dynamic>)['source'] == source,
                )
                .toList();
      }
    });
  }

  Future<void> _deleteAttempt(String docId) async {
    await FirebaseFirestore.instance
        .collection('quizAttempts')
        .doc(docId)
        .delete();
    await _loadAttempts();
  }

  Future<void> _deleteAllAttempts() async {
    for (final doc in _filteredAttempts) {
      await doc.reference.delete();
    }
    await _loadAttempts();
  }

  void _retakeQuiz(Map<String, dynamic> attempt) {
    final questions =
        (attempt['questions'] as List).map((q) {
          return QuizItem(
            id: q['id'] ?? '',
            question: q['question'],
            options: List<String>.from(q['options']),
            correctAnswer: q['correctAnswer'],
          );
        }).toList();

    final quiz = Quiz(
      docId: 'ai_quiz',
      prompt: attempt['prompt'],
      difficulty: 'N/A',
      number: questions.length,
      questions: questions,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => QuizScreen(
              quiz: quiz,
              teacherId: "ai_quiz",
              saveToHistory: false,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        centerTitle: true,
        title: const Text(
          "REVIEW",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: _filter,
            dropdownColor: const Color.fromARGB(255, 0, 0, 0),
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_alt, color: Colors.black),
            items:
                ['All', 'Made', 'Joined']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
            onChanged: (value) {
              _filter = value!;
              _applyFilter();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            tooltip: "Delete All",
            onPressed:
                _filteredAttempts.isEmpty
                    ? null
                    : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("Delete All"),
                              content: Text(
                                "Are you sure you want to delete all '${_filter.toLowerCase()}' quiz attempts?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "Delete All",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        await _deleteAllAttempts();
                      }
                    },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAttempts.isEmpty
              ? const Center(
                child: Text(
                  "No quiz found",
                  style: TextStyle(color: Colors.white),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filteredAttempts.length,
                itemBuilder: (context, index) {
                  final doc = _filteredAttempts[index];
                  final attempt = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;

                  final topic =
                      attempt['topic'] ?? attempt['prompt'] ?? 'Unknown Topic';
                  final timestamp = attempt['submittedAt'] as Timestamp?;
                  final date = timestamp?.toDate();
                  final formattedDate =
                      date != null
                          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                              "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
                          : "Unknown date";

                  final selectedAnswers = List<String>.from(
                    attempt['selectedAnswers'] ?? [],
                  );
                  final questions = List<Map<String, dynamic>>.from(
                    attempt['questions'] ?? [],
                  );

                  int score = 0;
                  for (int i = 0; i < questions.length; i++) {
                    final q = questions[i];
                    if (i < selectedAnswers.length &&
                        selectedAnswers[i] == q['correctAnswer']) {
                      score++;
                    }
                  }

                  return Card(
                    color: const Color(0xFF3B0C5F),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        "Topic: $topic",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Score: $score/${questions.length}\nSubmitted on: $formattedDate",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          if (attempt['source'] == 'ai')
                            ElevatedButton(
                              onPressed: () => _retakeQuiz(attempt),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB300),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text("Retake"),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text("Confirm Deletion"),
                                      content: const Text(
                                        "Are you sure you want to delete this attempt?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                await _deleteAttempt(docId);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
