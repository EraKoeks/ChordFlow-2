import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  static User? get currentUser {
    return _auth.currentUser;
  }

  static Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> sendPasswordReset({
    required String email,
  }) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  static Future<void> signOut() {
    return _auth.signOut();
  }

  static String errorMessage(
      FirebaseAuthException error,
      ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Dit e-mailadres is niet geldig.';
      case 'user-disabled':
        return 'Dit account is uitgeschakeld.';
      case 'user-not-found':
        return 'Er bestaat geen account met dit e-mailadres.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mailadres of wachtwoord is onjuist.';
      case 'email-already-in-use':
        return 'Er bestaat al een account met dit e-mailadres.';
      case 'weak-password':
        return 'Gebruik een sterker wachtwoord van minimaal 6 tekens.';
      case 'too-many-requests':
        return 'Te veel pogingen. Probeer het later opnieuw.';
      case 'network-request-failed':
        return 'Controleer je internetverbinding.';
      default:
        return error.message ??
            'Er is iets misgegaan. Probeer het opnieuw.';
    }
  }
}
