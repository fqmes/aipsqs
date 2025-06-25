import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'student';
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Input validation
    if (_name.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty) {
      setState(() {
        _error = "All fields are required";
        _loading = false;
      });
      return;
    }

    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text,
            password: _password.text,
          );

      await FirebaseFirestore.instance
          .collection('user_roles')
          .doc(userCred.user!.uid)
          .set({'role': _role, 'name': _name.text});

      if (mounted) {
        // Redirect to Login screen instead of dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_alt_1,
                size: 90,
                color: Color(0xFFFFB300),
              ),
              const SizedBox(height: 10),
              Text(
                "Create Account",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              _buildField("Full Name", _name, icon: Icons.person),
              const SizedBox(height: 16),
              _buildField("Email", _email, icon: Icons.email),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildDropdown(),
              const SizedBox(height: 20),

              if (_error != null)
                Text(_error!, style: GoogleFonts.poppins(color: Colors.red)),

              const SizedBox(height: 12),

              _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.person_add),
                      label: Text("Register", style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                child: Text(
                  "Already have an account? Login here",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required IconData icon,
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.white54),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Password", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3B0C5F),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _password,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: const Icon(Icons.lock, color: Colors.white54),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Role", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3B0C5F),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: _role,
            dropdownColor: const Color(0xFF3B0C5F),
            isExpanded: true,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            iconEnabledColor: Colors.white54,
            onChanged: (value) => setState(() => _role = value!),
            items:
                ['student', 'teacher']
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}
