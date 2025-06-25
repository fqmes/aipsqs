import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRole {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<String> getUserRole() async {
    String role = '';
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRoleSnapshot = await _firestore
            .collection('user_roles')
            .doc(user.uid)
            .get();
        role = userRoleSnapshot.data()?['role'];
      }
    } catch (e) {
      print("Error getting user role: $e");
    }
    return role;
  }
}