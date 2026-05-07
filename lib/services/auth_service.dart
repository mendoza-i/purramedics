
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purramedics/services/firestore_service.dart';

/// ============================================================================
/// AUTH SERVICE (REAL)
/// ----------------------------------------------------------------------------
/// Handles authentication via Firebase Auth.
/// FEATURES:
/// 1. Login/SignUp: Validates real credentials.
/// 2. Role Management: Simple role logic (Vet if email contains 'vet').
/// 3. Session State: Tracks the currently logged-in user.
/// ============================================================================
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current logged in role (Still inferred from email for simplicity in MVP)
  String? _currentUserRole;

  User? get currentUser => _auth.currentUser;
  bool get isVet => _currentUserRole == 'vet';
  bool get isLoggedIn => currentUser != null;

  // Init Role on App Start (if user is already logged in)
  Future<void> init() async {
    if (currentUser != null) {
      _determineRole(currentUser!.email!);
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      await _auth.signInWithEmailAndPassword(email: trimmedEmail, password: password);
      _determineRole(trimmedEmail);
      
      // SYNC USER TO FIRESTORE (Self-healing for existing users)
      if (_auth.currentUser != null) {
        try {
          await FirestoreService().saveUser(
            _auth.currentUser!.uid, 
            trimmedEmail, 
            _auth.currentUser!.displayName ?? "Returning User", // Use existing name or default
            _currentUserRole ?? "owner"
          );
        } catch (e) {
          print("Firestore sync failed during login (non-fatal): $e");
        }
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again. $e";
    }
  }

  // Sign Up
  Future<String?> signUp(String email, String password, bool isVet, {String? name}) async {
    try {
      final trimmedEmail = email.trim();
      final credential = await _auth.createUserWithEmailAndPassword(email: trimmedEmail, password: password);
      
      // Update Display Name if provided
      if (name != null && credential.user != null) {
        await credential.user!.updateDisplayName(name);
      }

      _determineRole(trimmedEmail);
      
      // SAVE TO FIRESTORE (For Vet Selector)
      if (credential.user != null) {
        try {
          await FirestoreService().saveUser(
            credential.user!.uid, 
            trimmedEmail, 
            name ?? "Unknown User", 
            _currentUserRole ?? "owner"
          );
        } catch (e) {
          print("Firestore sync failed during signUp (non-fatal): $e");
        }
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again. $e";
    }
  }

  // Update User Name
  Future<String?> updateUserName(String newName) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(newName);
        // Force reload socurrentUser.displayName updates locally
        await currentUser!.reload(); 
        return null;
      }
      return "User not logged in.";
    } on FirebaseAuthException catch (e) {
      return _getFriendlyErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. $e";
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    _currentUserRole = null;
  }

  // Helper to set role based on email pattern
  void _determineRole(String email) {
    if (email.toLowerCase().contains('vet') || email.toLowerCase().contains('doctor')) {
      _currentUserRole = 'vet';
    } else {
      _currentUserRole = 'owner';
    }
  }

  // Helper to map Firebase errors to user-friendly messages
  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password. Please try again.";
      case 'invalid-email':
        return "The email address is badly formatted.";
      case 'email-already-in-use':
        return "An account already exists for that email.";
      case 'weak-password':
        return "The password provided is too weak.";
      case 'network-request-failed':
        return "Please check your internet connection.";
      case 'too-many-requests':
        return "Too many attempts. Please try again later.";
      case 'user-disabled':
        return "This user account has been disabled.";
      case 'operation-not-allowed':
        return "Signing in with Email and Password is not enabled.";
      default:
        return "Authentication failed. (${e.code})"; // Fallback with code for debugging
    }
  }
}

