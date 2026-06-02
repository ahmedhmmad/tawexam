abstract interface class TokenProvider {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<void> clearTokens();
}
