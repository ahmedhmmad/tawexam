abstract class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}
