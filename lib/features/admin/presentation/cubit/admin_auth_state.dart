// lib/features/admin/presentation/cubit/admin_auth_state.dart
import 'package:equatable/equatable.dart';

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
  const AdminAuthSuccess(this.username);
  final String username;
  @override
  List<Object?> get props => [username];
}

class AdminAuthFailure extends AdminAuthState {
  const AdminAuthFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
