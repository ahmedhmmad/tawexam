import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/token_provider.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit({
    required TokenProvider tokenProvider,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            )),
        super(const AdminAuthInitial());

  final TokenProvider _tokenProvider;
  final Dio _dio;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AdminAuthLoading());
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = Map<String, dynamic>.from(
        response.data?['data'] as Map? ?? response.data ?? {},
      );
      final accessToken = '${data['accessToken'] ?? ''}';
      final refreshToken = data['refreshToken']?.toString();
      await _tokenProvider.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      emit(AdminAuthSuccess(username));
    } on DioException catch (e) {
      final message = (e.response?.data is Map)
          ? '${(e.response!.data as Map)['message'] ?? 'فشل تسجيل الدخول'}'
          : 'فشل تسجيل الدخول';
      emit(AdminAuthFailure(message));
    } catch (e) {
      emit(AdminAuthFailure(e.toString()));
    }
  }

  Future<void> logout() async {
    await _tokenProvider.clearTokens();
    emit(const AdminAuthInitial());
  }
}
