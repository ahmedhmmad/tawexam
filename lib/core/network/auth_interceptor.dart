import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'token_provider.dart';

class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  void onRequest(
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
}
