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

  /// Server origin without the API prefix, e.g. `https://host` for
  /// `https://host/api/v1`. Used to resolve relative media URLs.
  static String get serverOrigin {
    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  /// Resolves a stored media URL (relative `/uploads/...` or absolute) to a
  /// fully qualified URL the client can fetch. Returns null for empty input.
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$serverOrigin$url';
  }
}
