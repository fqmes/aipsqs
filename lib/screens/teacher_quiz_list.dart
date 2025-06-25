import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class TeacherQuizList extends StatefulWidget {
  const TeacherQuizList({super.key});

  @override
  State<TeacherQuizList> createState() => _TeacherQuizListState();
}

class _TeacherQuizListState extends State<TeacherQuizList> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('user_quizzes')
            .doc(user.uid)
            .collection('quizzes')
            .orderBy('createdAt', descending: true)
            .get();

    if (!mounted) return; // ✅ prevent setState if widget unmounted

    setState(() {
      _quizzes =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
      _loading = false;
    });
  }

  Future<void> _deleteQuiz(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('user_quizzes')
        .doc(user.uid)
        .collection('quizzes')
        .doc(id);

    final items = await ref.collection('quiz').get();
    for (final item in items.docs) {
      await item.reference.delete();
    }

    await ref.delete();
    if (mounted) await _loadQuizzes(); // ✅ prevent crash after deletion
  }

  Future<void> _deleteAllQuizzes() async {
    for (final quiz in List.from(_quizzes)) {
      await _deleteQuiz(quiz['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB300),
        title: const Text(
          "QUIZZES",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_quizzes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: "Delete All",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Delete All"),
                        content: const Text(
                          "Are you sure you want to delete all your quizzes?",
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
                if (confirm == true) await _deleteAllQuizzes();
              },
            ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _quizzes.isEmpty
              ? const Center(
                child: Text(
                  "You haven't created any quizzes yet.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = _quizzes[index];
                  final date = (quiz['createdAt'] as Timestamp?)?.toDate();
                  final createdDate =
                      date != null
                          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
                          : "Unknown";

                  return Card(
                    color: const Color(0xFF3B0C5F),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        "Topic: ${quiz['prompt']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Difficulty: ${quiz['difficulty']} | Questions: ${quiz['number']}\nCreated: $createdDate",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: quiz['id']),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Quiz code copied"),
                                ),
                              );
                            },
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
                                    (_) => AlertDialog(
                                      title: const Text("Delete Quiz?"),
                                      content: Text(
                                        "Are you sure you want to delete quiz '${quiz['prompt']}'?",
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
                                await _deleteQuiz(quiz['id']);
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
