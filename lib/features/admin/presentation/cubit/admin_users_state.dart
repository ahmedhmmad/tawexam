import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_user.dart';

sealed class AdminUsersState extends Equatable {
  const AdminUsersState();
  @override
  List<Object?> get props => [];
}

class AdminUsersLoading extends AdminUsersState {
  const AdminUsersLoading();
}

class AdminUsersError extends AdminUsersState {
  const AdminUsersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class AdminUsersLoaded extends AdminUsersState {
  const AdminUsersLoaded(this.users);
  final List<AdminUser> users;
  @override
  List<Object?> get props => [users];
}
