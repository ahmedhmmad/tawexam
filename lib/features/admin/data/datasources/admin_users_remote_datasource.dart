import 'package:dio/dio.dart';

import '../../domain/entities/admin_role.dart';
import '../../domain/entities/admin_user.dart';

abstract interface class AdminUsersRemoteDataSource {
  Future<List<AdminUser>> list();
  Future<void> create({
    required String username,
    required String password,
    required AdminRole role,
  });
  Future<void> update(String id, {String? username, AdminRole? role, bool? isActive});
  Future<void> resetPassword(String id, String password);
  Future<void> delete(String id);
}

class AdminUsersRemoteDataSourceImpl implements AdminUsersRemoteDataSource {
  const AdminUsersRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<AdminUser>> list() async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/users');
    final data = r.data?['data'];
    if (data is! List) return const [];
    return data
        .map((e) => AdminUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  @override
  Future<void> create({
    required String username,
    required String password,
    required AdminRole role,
  }) async {
    await _dio.post<void>('/admin/users', data: {
      'username': username,
      'password': password,
      'role': role.apiValue,
    });
  }

  @override
  Future<void> update(String id, {String? username, AdminRole? role, bool? isActive}) async {
    await _dio.put<void>('/admin/users/$id', data: {
      if (username != null) 'username': username,
      if (role != null) 'role': role.apiValue,
      if (isActive != null) 'isActive': isActive,
    });
  }

  @override
  Future<void> resetPassword(String id, String password) async {
    await _dio.post<void>('/admin/users/$id/reset-password', data: {'password': password});
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/admin/users/$id');
  }
}
