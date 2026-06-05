import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_interceptor.dart';
import 'refresh_token_interceptor.dart';

class ApiClient {
  ApiClient(
    AuthInterceptor authInterceptor,
    RefreshTokenInterceptor refreshTokenInterceptor,
  ) : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(refreshTokenInterceptor);
  }

  final Dio dio;
}
