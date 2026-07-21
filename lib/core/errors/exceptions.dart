/// CNG LIVE — Custom Exceptions
///
/// Thrown by the data source layer only (never by repositories or
/// above). Repositories catch these and convert them into typed
/// [Failure]s via [ErrorHandler].
class ServerException implements Exception {
  ServerException([this.message = 'Server error occurred']);
  final String message;
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache error occurred']);
  final String message;
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
}

class AuthException implements Exception {
  AuthException([this.message = 'Authentication error occurred']);
  final String message;
}
