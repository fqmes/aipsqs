import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/ai_quiz.dart';

class TeacherQuizGenerator extends StatefulWidget {
  final WorkersAI aiService;
  const TeacherQuizGenerator({super.key, required this.aiService});

  @override
  State<TeacherQuizGenerator> createState() => _TeacherQuizGeneratorState();
}

class _TeacherQuizGeneratorState extends State<TeacherQuizGenerator> {
  final _topicController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _difficulty = 'Medium';
  final _questionController = TextEditingController(text: '5');
  bool _loading = false;
  String? _quizId;

  Future<void> _generateQuiz() async {
    setState(() {
      _loading = true;
      _quizId = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final prompt = _topicController.text.trim();
      final count = int.tryParse(_questionController.text.trim()) ?? 0;

      if (prompt.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please enter a topic.")));
        return;
      }

      if (count < 1 || count > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Question count must be between 1 and 5."),
          ),
        );
        return;
      }

      final quizRef = await _firestore
          .collection('user_quizzes')
          .doc(user.uid)
          .collection('quizzes')
          .add({
            'prompt': prompt,
            'difficulty': _difficulty,
            'number': count,
            'createdAt': Timestamp.now(),
          });

      await _firestore.collection('user_quizzes').doc(user.uid).set({
        'created': true,
      }, SetOptions(merge: true));

      final raw = await widget.aiService.generateQuiz(
        prompt,
        _difficulty,
        count,
      );
      final questions =
          raw
              .map((data) {
                try {
                  return {
                    'question': data['question'],
                    'options': List<String>.from(data['options']),
                    'answer': data['answer'] ?? data['correct'],
                  };
                } catch (_) {
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>()
              .toList();

      if (questions.isEmpty) throw Exception("No valid questions generated");

      final quizColl = quizRef.collection('quiz');
      for (final q in questions) {
        await quizColl.add(q);
      }

      setState(() => _quizId = quizRef.id);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3B0C5F),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
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
          "QUIZ GENERATOR",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Generate Quiz Code",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField("Topic", _topicController),
                    const SizedBox(height: 10),
                    const Text(
                      "Difficulty",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B0C5F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: _difficulty,
                        dropdownColor: const Color(0xFF3B0C5F),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        onChanged:
                            (value) => setState(() => _difficulty = value!),
                        items:
                            const ["Easy", "Medium", "Hard"]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      "Number of Questions (1–5)",
                      _questionController,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _generateQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Generate"),
                    ),
                    if (_quizId != null) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _quizId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Quiz code copied")),
                          );
                        },
                        child: Text(
                          "Quiz Code: $_quizId (tap to copy)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}
