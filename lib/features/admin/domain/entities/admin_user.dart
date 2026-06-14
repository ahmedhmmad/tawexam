import 'package:equatable/equatable.dart';

import 'admin_role.dart';

class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String username;
  final AdminRole role;
  final bool isActive;
  final DateTime? createdAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: '${json['id'] ?? ''}',
      username: '${json['username'] ?? ''}',
      role: AdminRole.fromApi(json['role']?.toString()),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
    );
  }

  @override
  List<Object?> get props => [id, username, role, isActive, createdAt];
}
