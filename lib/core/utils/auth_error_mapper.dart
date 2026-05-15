import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthErrorMapper {
  static String message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'user-disabled' => 'This account is disabled.',
        'user-not-found' => 'No account exists for this email.',
        'wrong-password' ||
        'invalid-credential' => 'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Use a stronger password.',
        'network-request-failed' => 'Network connection failed. Try again.',
        _ => error.message ?? 'Authentication failed. Try again.',
      };
    }

    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => 'Google sign-in was cancelled.',
        GoogleSignInExceptionCode.interrupted =>
          'Google sign-in was interrupted.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'Google sign-in is not available on this device.',
        _ => error.description ?? 'Google sign-in failed. Try again.',
      };
    }

    return 'Something went wrong. Try again.';
  }
}
