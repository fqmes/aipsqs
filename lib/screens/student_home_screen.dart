import 'package:flutter/material.dart';
import '../services/ai_quiz.dart';
import 'joined_quiz_screen.dart';
import '../models/quiz.dart';
import '../services/user_quizzes.dart';
import 'quiz_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final WorkersAI aiService;

  const StudentHomeScreen({super.key, required this.aiService});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _codeController = TextEditingController();
  final _topicController = TextEditingController();
  final _numberController = TextEditingController(text: "5");
  String _selectedDifficulty = "Medium";

  final _userQuizService = UserQuizzes();
  bool _loading = false;

  Future<void> _joinQuiz() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _loading = true);

    final result = await _userQuizService.joinQuiz(code);

    setState(() => _loading = false);

    if (result != null) {
      final Quiz quiz = result['quiz'];
      final String teacherId = result['teacherId'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => JoinedQuizScreen(
                quiz: quiz,
                teacherId: teacherId,
                quizCode: code,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid quiz code.")));
    }
  }

  Future<void> _generateAIQuiz() async {
    final prompt = _topicController.text.trim();
    final difficulty = _selectedDifficulty;
    final count = int.tryParse(_numberController.text.trim()) ?? 0;

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

    setState(() => _loading = true);
    try {
      final raw = await widget.aiService.generateQuiz(
        prompt,
        difficulty,
        count,
      );
      print("📥 Raw AI Response: $raw");

      final questions =
          raw
              .map((data) {
                try {
                  return QuizItem.fromMap(data);
                } catch (e) {
                  print("⚠️ Skipped invalid question: $data | Error: $e");
                  return null;
                }
              })
              .whereType<QuizItem>()
              .toList();

      if (questions.isEmpty) {
        throw Exception("No valid questions generated.");
      }

      final quiz = Quiz(
        docId: 'ai_quiz',
        prompt: prompt,
        difficulty: difficulty,
        number: count,
        questions: questions,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(quiz: quiz, teacherId: "ai_quiz"),
        ),
      );
    } catch (e) {
      print("❌ Error generating quiz: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating quiz: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        centerTitle: true,
        title: const Text(
          "HOME",
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
                      "Join a Quiz",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField("Enter Code Here", _codeController),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _joinQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Join Quiz"),
                    ),
                    const Divider(height: 30, color: Colors.white54),
                    const Text(
                      "Generate Quiz",
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
                        value: _selectedDifficulty,
                        dropdownColor: const Color(0xFF3B0C5F),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        onChanged:
                            (value) =>
                                setState(() => _selectedDifficulty = value!),
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
                      "Number of Questions (1-5)",
                      _numberController,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _generateAIQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Generate"),
                    ),
                  ],
                ),
              ),
    );
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
}
