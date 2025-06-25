import 'package:flutter/material.dart';
import 'student_home_screen.dart';
import 'review_screen.dart';
import 'student_profile_screen.dart';
import '../services/ai_quiz.dart';

class StudentDashboard extends StatefulWidget {
  final WorkersAI aiService;

  const StudentDashboard({super.key, required this.aiService});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StudentHomeScreen(aiService: widget.aiService),
      ReviewScreen(aiService: widget.aiService),
      StudentProfileScreen(),
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
        unselectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        backgroundColor: const Color(0xFF3B0C5F),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Review'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
