import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController(text: "12345678");
  final _currentPasswordForEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _studentName = "";

  bool _obscureEmail = true;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isEditingName = false;
  bool _isEditingEmail = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('user_roles').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _studentName = doc['name'] ?? '';
        _nameController.text = doc['name'] ?? '';
        _emailController.text = user.email ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    try {
      final currentEmail = user?.email ?? "";

      // EMAIL UPDATE
      if (_isEditingEmail) {
        final newEmail = _emailController.text.trim();
        final password = _currentPasswordForEmailController.text.trim();

        if (password.isEmpty) {
          throw Exception("Enter current password to change email.");
        }

        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(newEmail)) {
          throw FormatException("Invalid email format.");
        }

        final cred = EmailAuthProvider.credential(
          email: currentEmail,
          password: password,
        );
        await user!.reauthenticateWithCredential(cred);
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      // PASSWORD UPDATE
      if (_isEditingPassword) {
        final password = _currentPasswordController.text.trim();
        if (password.isEmpty) {
          throw Exception("Enter current password to change password.");
        }
        final cred = EmailAuthProvider.credential(
          email: currentEmail,
          password: password,
        );
        await user!.reauthenticateWithCredential(cred);

        final newPassword = _newPasswordController.text.trim();
        final confirmPassword = _confirmPasswordController.text.trim();
        if (newPassword == confirmPassword) {
          await user.updatePassword(newPassword);
        } else {
          throw Exception("New passwords do not match.");
        }
      }

      // NAME UPDATE
      if (_isEditingName) {
        await _firestore.collection('user_roles').doc(user!.uid).update({
          'name': _nameController.text.trim(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      String message;
      if (e is FormatException) {
        message = e.message;
      } else if (e is FirebaseAuthException) {
        message = e.message ?? "An authentication error occurred.";
      } else {
        message = "Failed to update profile.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildLabeledField(
    String title,
    TextEditingController controller,
    bool enabled, {
    bool isPassword = false,
    bool obscure = false,
    void Function()? toggle,
    void Function()? onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF3B0C5F) : Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword && obscure,
                  enabled: enabled,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              if (isPassword && toggle != null)
                IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: toggle,
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white54),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F0033),
      appBar: AppBar(
        title: const Text(
          "PROFILE",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB300),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Hi, $_studentName 👋",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildLabeledField(
              "Name",
              _nameController,
              _isEditingName,
              obscure: false,
              onEdit: () => setState(() => _isEditingName = !_isEditingName),
            ),
            _buildLabeledField(
              "Email",
              _emailController,
              _isEditingEmail,
              obscure: _obscureEmail,
              isPassword: true,
              toggle: () => setState(() => _obscureEmail = !_obscureEmail),
              onEdit: () => setState(() => _isEditingEmail = !_isEditingEmail),
            ),
            if (_isEditingEmail)
              _buildLabeledField(
                "Type your password to change email",
                _currentPasswordForEmailController,
                true,
                isPassword: true,
                obscure: true,
              ),
            _buildLabeledField(
              "Reset Password",
              _currentPasswordController,
              _isEditingPassword,
              isPassword: true,
              obscure: _obscureCurrent,
              toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              onEdit: () {
                setState(() {
                  _isEditingPassword = !_isEditingPassword;
                  _currentPasswordController.clear();
                });
              },
            ),
            if (_isEditingPassword) ...[
              _buildLabeledField(
                "New Password",
                _newPasswordController,
                true,
                isPassword: true,
                obscure: _obscureNew,
                toggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              _buildLabeledField(
                "Confirm New Password",
                _confirmPasswordController,
                true,
                isPassword: true,
                obscure: _obscureConfirm,
                toggle:
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 16,
                        ),
                      ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _logout,
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
