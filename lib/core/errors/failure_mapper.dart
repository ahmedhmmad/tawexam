import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

Failure mapExceptionToFailure(Object error) {
  return switch (error) {
    DioException() => _mapDioException(error),
    NetworkException() => NetworkFailure(error.message, code: error.code),
    AuthException() => AuthFailure(error.message, code: error.code),
    StorageException() => StorageFailure(error.message, code: error.code),
    SessionExpiredException() => SessionExpiredFailure(
        error.message,
        code: error.code,
      ),
    ValidationException() => ValidationFailure(error.message, code: error.code),
    ServerException() => ServerFailure(error.message, code: error.code),
    _ => ServerFailure(error.toString()),
  };
}

Failure _mapDioException(DioException error) {
  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return const SessionExpiredFailure('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
  }
  if (statusCode != null && statusCode >= 500) {
    return ServerFailure('حدث خطأ في الخادم', code: '$statusCode');
  }
  return NetworkFailure(error.message ?? 'تعذر الاتصال بالخادم');
}
