import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import foundation for debugPrint
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register user with email and password
  Future<String?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? certificateLink,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Determine role based on certificate link
        String role =
            certificateLink != null && certificateLink.isNotEmpty
                ? 'ngo'
                : 'volunteer';

        // Create user document in Firestore
        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          role: role,
          username: username,
          certificateLink: certificateLink,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return null; // Success
      }
      return 'Registration failed';
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        if (!user.emailVerified) {
          await signOut();
          return 'Please verify your email before signing in';
        }

        // Load user data from Firestore
        await _loadUserData(user.uid);
        notifyListeners();
        return null; // Success
      }
      return 'Sign in failed';
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Send password reset email
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Resend email verification
  Future<String?> resendEmailVerification() async {
    try {
      User? user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null; // Success
      }
      return 'Unable to send verification email';
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    User? user = currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromDocument(
          uid,
          doc.data() as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Error loading user data: $e'); // Use debugPrint
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }

  // Initialize user data on app start
  Future<void> initializeUser() async {
    User? user = currentUser;
    if (user != null && user.emailVerified) {
      await _loadUserData(user.uid);
      notifyListeners();
    }
  }
}
