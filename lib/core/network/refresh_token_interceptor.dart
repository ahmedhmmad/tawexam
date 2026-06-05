import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'token_provider.dart';

class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required Dio dio,
    required TokenProvider tokenProvider,
  }) : _dio = dio,
       _tokenProvider = tokenProvider;

  final Dio _dio;
  final TokenProvider _tokenProvider;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshRequest = requestOptions.path == ApiConfig.refreshEndpoint;
    final hasRetried = requestOptions.extra['retried'] == true;

    if (!isUnauthorized || isRefreshRequest || hasRetried) {
      if (isUnauthorized && hasRetried) {
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

    try {
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        ApiConfig.refreshEndpoint,
        data: {'refreshToken': refreshToken},
      );
      final data = Map<String, dynamic>.from(
        refreshResponse.data?['data'] as Map? ??
            refreshResponse.data ??
            const {},
      );
      final accessToken = '${data['accessToken'] ?? ''}';
      final nextRefreshToken = data['refreshToken']?.toString();
      await _tokenProvider.saveTokens(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );

      requestOptions.headers[ApiConfig.authorizationHeader] =
          '${ApiConfig.bearerPrefix} $accessToken';
      requestOptions.extra['retried'] = true;
      final retriedResponse = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(retriedResponse);
    } catch (_) {
      await _tokenProvider.clearTokens();
      handler.next(err);
    }
  }
}
