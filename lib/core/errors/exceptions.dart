/// Data-layer exceptions thrown by datasources.
///
/// These are caught by repositories and converted to [Failure] objects.

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error.']);
  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error.']);
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error.']);
  @override
  String toString() => 'CacheException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Unauthorized.']);
  @override
  String toString() => 'UnauthorizedException: $message';
}
