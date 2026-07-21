import '../errors/failure.dart';

/// CNG LIVE — Result Wrapper
///
/// Every repository method returns `Result<T>` instead of throwing —
/// forces ViewModels to explicitly handle both success and failure
/// paths (Step 22, Section 4 & 16).
///
/// Usage:
///   final result = await pumpRepository.getPumpById(id);
///   result.when(
///     success: (pump) => ...,
///     failure: (failure) => ...,
///   );
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Error<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Error<T>) return failure(self.failure);
    throw StateError('Unreachable');
  }

  /// Returns the success value, or null if this is a failure.
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}
