// lib/features/admin/presentation/cubit/admin_auth_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/admin_role.dart';

sealed class AdminAuthState extends Equatable {
  const AdminAuthState();
  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminAuthSuccess extends AdminAuthState {
  const AdminAuthSuccess({required this.username, required this.role});
  final String username;
  final AdminRole role;
  @override
  List<Object?> get props => [username, role];
}

class AdminAuthFailure extends AdminAuthState {
  const AdminAuthFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
