import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../data/datasources/admin_users_remote_datasource.dart';
import '../../domain/entities/admin_role.dart';
import 'admin_users_state.dart';

class AdminUsersCubit extends Cubit<AdminUsersState> {
  AdminUsersCubit(this._dataSource) : super(const AdminUsersLoading());

  final AdminUsersRemoteDataSource _dataSource;

  Future<void> load() async {
    emit(const AdminUsersLoading());
    try {
      emit(AdminUsersLoaded(await _dataSource.list()));
    } catch (e) {
      emit(AdminUsersError(mapExceptionToFailure(e).message));
    }
  }

  /// Runs a write then reloads. Returns null on success, or an error message
  /// for the caller to surface (so the list isn't replaced by an error state).
  Future<String?> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    }
  }

  Future<String?> create({
    required String username,
    required String password,
    required AdminRole role,
  }) =>
      _mutate(() => _dataSource.create(username: username, password: password, role: role));

  Future<String?> update(String id, {String? username, AdminRole? role, bool? isActive}) =>
      _mutate(() => _dataSource.update(id, username: username, role: role, isActive: isActive));

  Future<String?> resetPassword(String id, String password) =>
      _mutate(() => _dataSource.resetPassword(id, password));

  Future<String?> delete(String id) => _mutate(() => _dataSource.delete(id));
}
