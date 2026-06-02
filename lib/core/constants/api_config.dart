class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tawexam.ps',
  );
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);
  static const authorizationHeader = 'Authorization';
  static const bearerPrefix = 'Bearer';
}
