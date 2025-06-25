import 'package:aipsqs/models/quiz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserQuizzes {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  get firestore => _firestore;

  Future<List<Quiz>> getQuizzes() async {
    List<Quiz> quizzes = [];
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;
        final roleDoc =
            await _firestore.collection('user_roles').doc(userId).get();
        final role = roleDoc.data()?['role'];

        if (role == 'teacher') {
          final teacherQuizzes =
              await _firestore
                  .collection('user_quizzes')
                  .doc(userId)
                  .collection('quizzes')
                  .get();
          for (var doc in teacherQuizzes.docs) {
            quizzes.add(Quiz.fromMap(doc.data(), doc.id));
          }
        } else {
          // 1. Quizzes the student created (AI-generated)
          final studentQuizzes =
              await _firestore
                  .collection('user_quizzes')
                  .doc(userId)
                  .collection('quizzes')
                  .get();
          for (var doc in studentQuizzes.docs) {
            quizzes.add(Quiz.fromMap(doc.data(), doc.id));
          }

          // 2. Quizzes the student joined and completed
          final teachers = await _firestore.collection('user_quizzes').get();
          for (var teacher in teachers.docs) {
            final quizzesSnap =
                await _firestore
                    .collection('user_quizzes')
                    .doc(teacher.id)
                    .collection('quizzes')
                    .get();
            for (var quizDoc in quizzesSnap.docs) {
              final participant =
                  await _firestore
                      .collection('user_quizzes')
                      .doc(teacher.id)
                      .collection('quizzes')
                      .doc(quizDoc.id)
                      .collection('participants')
                      .doc(userId)
                      .get();
              if (participant.exists && participant.data()?['score'] != null) {
                quizzes.add(Quiz.fromMap(quizDoc.data(), quizDoc.id));
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error in getQuizzes: $e");
    }
    return quizzes;
  }

  Future<List<QuizItem>> getQuizItems(String quizId, String teacherId) async {
    List<QuizItem> items = [];
    try {
      final snapshot =
          await _firestore
              .collection('user_quizzes')
              .doc(teacherId)
              .collection('quizzes')
              .doc(quizId)
              .collection('quiz')
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('question') &&
            data.containsKey('options') &&
            data.containsKey('answer')) {
          items.add(QuizItem.fromMap(data));
        }
      }
    } catch (e) {
      print("❌ Error in getQuizItems: $e");
    }
    return items;
  }

  Future<Quiz> addQuiz(String prompt, String difficulty, int number) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final ref = await _firestore
          .collection('user_quizzes')
          .doc(user.uid)
          .collection('quizzes')
          .add({'prompt': prompt, 'difficulty': difficulty, 'number': number});

      await _firestore.collection('user_quizzes').doc(user.uid).set({
        'created': true,
      }, SetOptions(merge: true));

      return Quiz(
        docId: ref.id,
        prompt: prompt,
        difficulty: difficulty,
        number: number,
        questions: [],
      );
    } catch (e) {
      print("Error adding quiz: $e");
      rethrow;
    }
  }

  Future<void> addQuizItem(String docId, QuizItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final ref = _firestore
          .collection('user_quizzes')
          .doc(user.uid)
          .collection('quizzes')
          .doc(docId)
          .collection('quiz');

      await ref.add({
        'question': item.question,
        'answer': item.correctAnswer,
        'options': item.options,
      });
    } catch (e) {
      print("Error in addQuizItem: $e");
    }
  }

  Future<void> deleteQuiz(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final items =
          await _firestore
              .collection('user_quizzes')
              .doc(user.uid)
              .collection('quizzes')
              .doc(docId)
              .collection('quiz')
              .get();
      for (var doc in items.docs) {
        await doc.reference.delete();
      }
      await _firestore
          .collection('user_quizzes')
          .doc(user.uid)
          .collection('quizzes')
          .doc(docId)
          .delete();
    } catch (e) {
      print("Error in deleteQuiz: $e");
    }
  }

  Future<Map<String, dynamic>?> joinQuiz(String code) async {
    try {
      final allTeachers = await _firestore.collection('user_quizzes').get();

      for (var teacher in allTeachers.docs) {
        final quizSnap =
            await _firestore
                .collection('user_quizzes')
                .doc(teacher.id)
                .collection('quizzes')
                .doc(code)
                .get();

        if (quizSnap.exists && quizSnap.data() != null) {
          final quizData = quizSnap.data()!;
          final quiz = Quiz.fromMap(quizData, code);

          return {'quiz': quiz, 'teacherId': teacher.id};
        }
      }
    } catch (e) {
      print("🔥 Error in joinQuiz: $e");
    }
    return null;
  }

  Future<int> submitScore(String docId, int score, String teacherId) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final participantRef = _firestore
          .collection('user_quizzes')
          .doc(teacherId)
          .collection('quizzes')
          .doc(docId)
          .collection('participants')
          .doc(user.uid);

      final exists = await participantRef.get();
      if (exists.exists) {
        await participantRef.update({'score': score});
        return score;
      }
    } catch (e) {
      print("Error in submitScore: $e");
    }
    return 0;
  }

  Future<int> getScore(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final teachers = await _firestore.collection('user_quizzes').get();
      for (var teacher in teachers.docs) {
        final scoreDoc =
            await _firestore
                .collection('user_quizzes')
                .doc(teacher.id)
                .collection('quizzes')
                .doc(docId)
                .collection('participants')
                .doc(user.uid)
                .get();
        if (scoreDoc.exists) {
          final data = scoreDoc.data();
          if (data?['score'] != null) {
            return data!['score'];
          }
        }
      }
    } catch (e) {
      print("Error in getScore: $e");
    }
    return 0;
  }

  Future<bool> canRetakeQuiz(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final teachers = await _firestore.collection('user_quizzes').get();
      for (var teacher in teachers.docs) {
        final retakeDoc =
            await _firestore
                .collection('user_quizzes')
                .doc(teacher.id)
                .collection('quizzes')
                .doc(docId)
                .collection('participants')
                .doc(user.uid)
                .get();
        if (retakeDoc.exists) {
          return true;
        }
      }
    } catch (e) {
      print("Error checking retake: $e");
    }
    return false;
  }

  Future<Map<String, dynamic>> getProgressData() async {
    final user = _auth.currentUser;
    Map<String, dynamic> progress = {};

    if (user == null) return progress;

    try {
      final teachers = await _firestore.collection('user_quizzes').get();
      for (var teacher in teachers.docs) {
        final quizzes =
            await _firestore
                .collection('user_quizzes')
                .doc(teacher.id)
                .collection('quizzes')
                .get();
        for (var quiz in quizzes.docs) {
          final score = await getScore(quiz.id);
          progress[quiz.id] = score;
        }
      }
    } catch (e) {
      print("Error in getProgressData: $e");
    }

    return progress;
  }

  Future<Map<String, String>> getAnswers(String quizId) async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final doc =
        await _firestore
            .collection("user_quizzes")
            .doc(user.uid)
            .collection("history")
            .doc(quizId)
            .get();
    final data = doc.data();
    if (data == null) return {};
    final answers = data['answers'] as Map<String, dynamic>? ?? {};
    return answers.map((key, value) => MapEntry(key, value.toString()));
  }
}
