import 'package:flutter/material.dart';

import 'teacher_quiz_generator.dart';
import 'teacher_quiz_list.dart';
import 'teacher_profile_screen.dart';
import 'student_attempt_screen.dart';
import '../services/ai_quiz.dart';

class TeacherDashboard extends StatefulWidget {
  final WorkersAI aiService;

  const TeacherDashboard({super.key, required this.aiService});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TeacherQuizGenerator(aiService: widget.aiService),
      const TeacherQuizList(),
      const StudentAttemptsScreen(), // ✅ new
      const TeacherProfileScreen(),
    ];
  }

  void _onScreenTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onScreenTapped,
        selectedItemColor: const Color(0xFFFFB300),
        unselectedItemColor: const Color.fromARGB(179, 0, 0, 0),
        backgroundColor: const Color(0xFF3B0C5F),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.create), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Attempts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
