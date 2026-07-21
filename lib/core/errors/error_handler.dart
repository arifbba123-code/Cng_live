import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logging/app_logger.dart';
import 'exceptions.dart';
import 'failure.dart';

/// CNG LIVE — Central Error Mapper
///
/// The single place raw exceptions (Firebase, network, cache) become
/// typed [Failure]s. Called from repository implementations only.
/// Also responsible for logging the raw error before it's translated,
/// so we never lose debugging context (Step 22, Section 18).
class ErrorHandler {
  ErrorHandler._();

  static Failure handle(Object error, {String? context}) {
    AppLogger.error(
      'ErrorHandler${context != null ? " [$context]" : ""}',
      error,
    );

    if (error is FirebaseAuthException) {
      return AuthFailure(_mapFirebaseAuthMessage(error.code));
    }

    if (error is FirebaseException) {
      return ServerFailure(_mapFirestoreMessage(error.code));
    }

    if (error is NetworkException) {
      return const NetworkFailure();
    }

    if (error is CacheException) {
      return const ServerFailure('Could not load saved data.');
    }

    if (error is AuthException) {
      return AuthFailure(error.message);
    }

    return const UnknownFailure();
  }

  static String _mapFirebaseAuthMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'That phone number looks invalid. Please check and try again.';
      case 'invalid-verification-code':
        return 'Incorrect OTP. Try again.';
      case 'session-expired':
        return 'OTP expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirestoreMessage(String code) {
    switch (code) {
      case 'unavailable':
        return "You're offline — showing last saved data.";
      case 'permission-denied':
        return "You don't have permission to do that.";
      case 'not-found':
        return "We couldn't find what you were looking for.";
      default:
        return 'Something went wrong on our end.';
    }
  }
}
