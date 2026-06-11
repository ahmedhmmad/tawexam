import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Maps any thrown error to a [Failure] carrying a user-friendly Arabic
/// message. Raw exception text must never reach the UI.
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
    _ => const ServerFailure('حدث خطأ غير متوقع، يرجى المحاولة لاحقاً'),
  };
}

/// Arabic translations for backend error codes the student can encounter.
const _backendCodeMessages = <String, String>{
  'INVALID_CREDENTIALS': 'رقم الجلوس أو كلمة المرور غير صحيحة',
  'EXAM_NOT_AVAILABLE': 'لا يوجد امتحان متاح حالياً',
  'EXAM_NOT_FOUND': 'الامتحان غير موجود',
  'EXAM_NOT_STARTED': 'لم يبدأ الامتحان بعد',
  'EXAM_TIME_EXPIRED': 'انتهى وقت الامتحان',
  'MAX_ATTEMPTS_REACHED': 'لقد استنفدت جميع محاولات هذا الامتحان',
  'SESSION_NOT_ACTIVE': 'انتهت جلسة الامتحان',
  'SESSION_NOT_FOUND': 'جلسة الامتحان غير موجودة',
  'RESULT_NOT_FOUND': 'النتيجة غير متوفرة بعد',
  'RATE_LIMITED': 'محاولات كثيرة، يرجى الانتظار قليلاً',
  'VALIDATION_ERROR': 'البيانات المدخلة غير صحيحة',
};

Failure _mapDioException(DioException error) {
  // The auth interceptor wraps an already-mapped Failure when token refresh
  // fails — pass it through untouched.
  if (error.error is Failure) return error.error! as Failure;

  // Connectivity-level problems (no response from the server)
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure(
        'انتهت مهلة الاتصال، تحقق من الإنترنت وحاول مجدداً',
      );
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت',
      );
    case DioExceptionType.cancel:
      return const NetworkFailure('تم إلغاء الطلب');
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final statusCode = error.response?.statusCode;
  final backendCode = _readBackendCode(error.response?.data);
  if (statusCode == null) {
    return const NetworkFailure(
      'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت',
    );
  }
  if (statusCode == 401) {
    // Wrong login credentials also come back as 401 — don't call it an
    // expired session.
    if (backendCode == 'INVALID_CREDENTIALS') {
      return const AuthFailure(
        'رقم الجلوس أو كلمة المرور غير صحيحة',
        code: 'INVALID_CREDENTIALS',
      );
    }
    return const SessionExpiredFailure('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
  }
  if (statusCode >= 500) {
    return ServerFailure(
      'حدث خطأ في الخادم، يرجى المحاولة لاحقاً',
      code: '$statusCode',
    );
  }

  // 4xx: translate the backend's error code when we know it
  final translated = backendCode == null
      ? null
      : _backendCodeMessages[backendCode];
  return ValidationFailure(
    translated ?? 'تعذر تنفيذ الطلب، يرجى المحاولة لاحقاً',
    code: backendCode ?? '$statusCode',
  );
}

String? _readBackendCode(Object? body) {
  if (body is! Map) return null;
  final errorField = body['error'];
  if (errorField is! Map) return null;
  final code = errorField['code'];
  return code is String && code.isNotEmpty ? code : null;
}
