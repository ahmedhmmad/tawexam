// lib/features/admin/presentation/cubit/admin_auth_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../../../core/errors/failure_mapper.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this._apiClient, this._tokenProvider)
      : super(const AdminAuthInitial());

  final ApiClient _apiClient;
  final TokenProvider _tokenProvider;

  /// Check if we have a stored token and validate it
  Future<void> checkSession() async {
    final token = await _tokenProvider.readAccessToken();
    if (token != null && token.isNotEmpty) {
      emit(const AdminAuthSuccess('admin'));
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
      final data =
          Map<String, dynamic>.from(r.data?['data'] as Map? ?? {});
      await _tokenProvider.saveTokens(
        accessToken: '${data['accessToken']}',
        refreshToken: data['refreshToken']?.toString(),
      );
      emit(AdminAuthSuccess(
          '${data['user']?['username'] ?? username}'));
    } catch (e) {
      emit(AdminAuthFailure(mapExceptionToFailure(e).message));
    }
  }

  Future<void> logout() async {
    await _tokenProvider.clearTokens();
    emit(const AdminAuthInitial());
  }
}
