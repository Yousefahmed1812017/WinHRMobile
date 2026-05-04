/// Domain-level failure classes used in the Result/Either pattern.
///
/// Each feature's repository catches exceptions and returns [Failure].
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure from the server (HTTP 4xx/5xx).
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Failure due to network issues (no internet, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Failure due to local cache/storage issues.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error.']);
}

/// Failure when the user is not authenticated.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required.']);
}

/// Generic / unknown failure.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
