// lib/features/admin/presentation/cubit/admin_auth_cubit.dart
import 'dart:async';

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
    // Redirect immediately: read the refresh token, clear the local session,
    // and flip to logged-out state right away so the gate shows the login page
    // without waiting on the network. Revoke the refresh token server-side in
    // the background (best effort).
    String? refreshToken;
    try {
      refreshToken = await _tokenProvider.readRefreshToken();
    } catch (_) {
      // ignore storage errors
    }
    await _tokenProvider.clearTokens();
    emit(const AdminAuthInitial());

    if (refreshToken != null && refreshToken.isNotEmpty) {
      final token = refreshToken;
      unawaited(() async {
        try {
          await _apiClient.dio.post<void>('/auth/logout', data: {'refreshToken': token});
        } catch (_) {
          // best effort — already logged out locally
        }
      }());
    }
  }
}
