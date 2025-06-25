import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import '../services/ai_quiz.dart';

class LandingScreen extends StatefulWidget {
  final WorkersAI aiService;
  const LandingScreen({super.key, required this.aiService});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Future<Widget> _determineHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Placeholder();

    final roleDoc =
        await FirebaseFirestore.instance
            .collection('user_roles')
            .doc(user.uid)
            .get();

    final role = roleDoc.data()?['role'] ?? 'student';

    if (role == 'teacher') {
      return  TeacherDashboard(aiService: widget.aiService);
    } else {
      final aiService = await WorkersAI.create(FirebaseFirestore.instance);
      return StudentDashboard(aiService: aiService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }
}
