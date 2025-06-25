import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'controllers/quiz_controller.dart';
import 'services/ai_quiz.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_attempt_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final aiService = await WorkersAI.create(firestore);

  runApp(MyApp(aiService: aiService));
}

class MyApp extends StatelessWidget {
  final WorkersAI aiService;
  const MyApp({super.key, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuizController(aiService)),
      ],
      child: MaterialApp(
        title: 'AIPSQS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1F0033),
          primaryColor: const Color(0xFFFFB300),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFB300),
            secondary: Colors.deepPurple,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF3B0C5F),
            selectedItemColor: Color(0xFFFFB300),
            unselectedItemColor: Color.fromARGB(179, 0, 0, 0),
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/student_home': (context) => StudentHomeScreen(aiService: aiService),
          '/login': (context) => LoginScreen(),
          '/student_attempts': (context) => const StudentAttemptsScreen(),
        },
      ),
    );
  }
}
