import 'package:equatable/equatable.dart';

/// CNG LIVE — Failure Types
///
/// Repositories never throw raw exceptions up to ViewModels (Step 22,
/// Section 16). Every repository method returns a [Result] wrapping
/// either a success value or one of these typed failures, which the
/// ViewModel then maps to a user-friendly message — never showing raw
/// Firebase error text to a driver.
abstract class Failure extends Equatable {
  const Failure(this.message);

  /// User-friendly message — safe to show directly in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "You're offline right now."]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our end.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = "We couldn't find what you were looking for."]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission is required to continue.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}
