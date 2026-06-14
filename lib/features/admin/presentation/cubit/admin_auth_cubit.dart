// lib/features/admin/presentation/cubit/admin_auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../domain/entities/admin_role.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this._apiClient, this._tokenProvider)
      : super(const AdminAuthInitial());

  final ApiClient _apiClient;
  final TokenProvider _tokenProvider;

  /// Restore the session on app startup: if a token exists, ask the backend
  /// who we are (real username + role) instead of trusting the token blindly.
  Future<void> checkSession() async {
    final token = await _tokenProvider.readAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      final r = await _apiClient.dio.get<Map<String, dynamic>>('/admin/auth/me');
      final user = Map<String, dynamic>.from(r.data?['data'] as Map? ?? {});
      emit(AdminAuthSuccess(
        username: '${user['username'] ?? ''}',
        role: AdminRole.fromApi(user['role']?.toString()),
      ));
    } catch (_) {
      // Token invalid/expired or backend unreachable — clear and show login.
      await _tokenProvider.clearTokens();
      emit(const AdminAuthInitial());
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AdminAuthLoading());
    try {
      final r = await _apiClient.dio.post<Map<String, dynamic>>(
        '/admin/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = Map<String, dynamic>.from(r.data?['data'] as Map? ?? {});
      final user = Map<String, dynamic>.from(data['user'] as Map? ?? {});
      await _tokenProvider.saveTokens(
        accessToken: '${data['accessToken']}',
        refreshToken: data['refreshToken']?.toString(),
      );
      emit(AdminAuthSuccess(
        username: '${user['username'] ?? username}',
        role: AdminRole.fromApi(user['role']?.toString()),
      ));
    } catch (e) {
      emit(AdminAuthFailure(mapExceptionToFailure(e).message));
    }
  }

  Future<void> logout() async {
    // Revoke the refresh token server-side before clearing locally (best
    // effort — clear regardless so the user always ends up logged out).
    try {
      final refreshToken = await _tokenProvider.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // ignore network/logout errors
    }
    await _tokenProvider.clearTokens();
    emit(const AdminAuthInitial());
  }
}
