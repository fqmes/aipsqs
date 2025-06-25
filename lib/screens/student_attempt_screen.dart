import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aipsqs/screens/student_quiz_review_screen.dart';

class StudentAttemptsScreen extends StatefulWidget {
  const StudentAttemptsScreen({super.key});

  @override
  State<StudentAttemptsScreen> createState() => _StudentAttemptsScreenState();
}

class _StudentAttemptsScreenState extends State<StudentAttemptsScreen> {
  bool _loading = true;
  Map<String, List<Map<String, dynamic>>> _groupedAttempts = {};

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final teacher = FirebaseAuth.instance.currentUser;
    if (teacher == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('quizAttempts')
            .where('teacherId', isEqualTo: teacher.uid)
            .where('source', isEqualTo: 'teacher')
            .orderBy('submittedAt', descending: true)
            .get();

    final attempts = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['userId'];
        final userDoc =
            await FirebaseFirestore.instance
                .collection('user_roles')
                .doc(userId)
                .get();

        final studentName = userDoc.data()?['name'] ?? "Unknown";
        final topic = data['topic'] ?? data['prompt'] ?? "Unknown Topic";
        final questions = List<Map<String, dynamic>>.from(data['questions']);
        final answers = List<String>.from(data['selectedAnswers'] ?? []);
        final date = (data['submittedAt'] as Timestamp).toDate();

        int score = 0;
        for (int i = 0; i < questions.length; i++) {
          if (i < answers.length &&
              answers[i] == questions[i]['correctAnswer']) {
            score++;
          }
        }

        return {
          'student': studentName,
          'topic': topic,
          'score': score,
          'total': questions.length,
          'date': date,
          'docId': doc.id,
        };
      }),
    );

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final attempt in attempts) {
      final topic = attempt['topic'] as String;
      grouped.putIfAbsent(topic, () => []).add(attempt);
    }

    if (mounted) {
      setState(() {
        _groupedAttempts = grouped;
        _loading = false;
      });
    }
  }

  Future<void> _deleteTopic(String topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete All '$topic' Attempts"),
            content: Text(
              "Are you sure you want to delete all student attempts for '$topic'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
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
      final attempts = _groupedAttempts[topic] ?? [];
      for (final attempt in attempts) {
        await FirebaseFirestore.instance
            .collection('quizAttempts')
            .doc(attempt['docId'])
            .delete();
      }
      _loadAttempts();
    }
  }

  Future<void> _deleteAllTopics() async {
    for (final topic in _groupedAttempts.keys) {
      final attempts = _groupedAttempts[topic] ?? [];
      for (final attempt in attempts) {
        await FirebaseFirestore.instance
            .collection('quizAttempts')
            .doc(attempt['docId'])
            .delete();
      }
    }
    _loadAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        centerTitle: true,
        title: const Text(
          "STUDENT ATTEMPTS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _groupedAttempts.isEmpty
                    ? null
                    : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text("Delete All Attempts"),
                              content: const Text(
                                "Are you sure you want to delete ALL quiz attempts across all topics?",
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
                        await _deleteAllTopics();
                      }
                    },
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Delete All Attempts",
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _groupedAttempts.isEmpty
              ? const Center(
                child: Text(
                  "No student attempts found.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children:
                    _groupedAttempts.entries.map((entry) {
                      final topic = entry.key;
                      final attempts = entry.value;

                      return Card(
                        color: const Color(0xFF2E0846),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.white,
                          title: Text(
                            topic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _deleteTopic(topic),
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                            ),
                          ),
                          children:
                              attempts.map((attempt) {
                                final date = attempt['date'] as DateTime;
                                final formattedDate =
                                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B0C5F),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Student: ${attempt['student']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Score: ${attempt['score']} / ${attempt['total']}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        "Submitted: $formattedDate",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          StudentQuizReviewScreen(
                                                            docId:
                                                                attempt['docId'],
                                                          ),
                                                ),
                                              );
                                            },
                                            child: const Text("View Answers"),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        "Delete Attempt",
                                                      ),
                                                      content: const Text(
                                                        "Are you sure you want to delete this student's quiz attempt?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: const Text(
                                                            "Cancel",
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: const Text(
                                                            "Delete",
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirm == true) {
                                                await FirebaseFirestore.instance
                                                    .collection('quizAttempts')
                                                    .doc(attempt['docId'])
                                                    .delete();
                                                _loadAttempts();
                                              }
                                            },
                                            icon: const Icon(Icons.delete),
                                            label: const Text("Delete"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    }).toList(),
              ),
    );
  }
}
