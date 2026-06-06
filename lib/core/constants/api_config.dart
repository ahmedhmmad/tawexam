import '../config/env_config.dart';

class ApiConfig {
  const ApiConfig._();

  static const baseUrl = EnvConfig.apiBaseUrl;
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);
  static const authorizationHeader = 'Authorization';
  static const bearerPrefix = 'Bearer';
  static const refreshEndpoint = '/auth/refresh';
}
