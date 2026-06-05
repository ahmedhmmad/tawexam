import 'package:dio/dio.dart';
import '../constants/api_config.dart';
import '../errors/failures.dart';
import 'token_provider.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenProvider, {Dio? authDio})
      : _authDio = authDio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ));

  final TokenProvider _tokenProvider;
  final Dio _authDio;
  final Set<String> _retrying = {};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConfig.authorizationHeader] =
          '${ApiConfig.bearerPrefix} $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final requestKey = '${options.method}:${options.path}';

    final is401 = err.response?.statusCode == 401;
    final isRefresh = options.path == ApiConfig.refreshEndpoint;
    final alreadyRetrying = _retrying.contains(requestKey);

    if (!is401 || isRefresh || alreadyRetrying) {
      if (is401 && alreadyRetrying) {
        _retrying.remove(requestKey);
        await _tokenProvider.clearTokens();
      }
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenProvider.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokenProvider.clearTokens();
      handler.next(err);
      return;
    }

    _retrying.add(requestKey);
    try {
      final resp = await _authDio.post<Map<String, dynamic>>(
        ApiConfig.refreshEndpoint,
        data: {'refreshToken': refreshToken},
      );
      final data = Map<String, dynamic>.from(
        resp.data?['data'] as Map? ?? resp.data ?? {},
      );
      final newAccess = '${data['accessToken'] ?? ''}';
      final newRefresh = data['refreshToken']?.toString();
      await _tokenProvider.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      options.headers[ApiConfig.authorizationHeader] =
          '${ApiConfig.bearerPrefix} $newAccess';
      _retrying.remove(requestKey);
      final retried = await _authDio.fetch<dynamic>(options);
      handler.resolve(retried);
    } catch (_) {
      _retrying.remove(requestKey);
      await _tokenProvider.clearTokens();
      handler.next(DioException(
        requestOptions: options,
        error: const SessionExpiredFailure('Session expired'),
        type: DioExceptionType.badResponse,
      ));
    }
  }
}
