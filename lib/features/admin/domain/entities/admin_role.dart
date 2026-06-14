/// Admin roles, mirroring the backend `AdminRole` enum. Drives nav gating.
enum AdminRole {
  superAdmin,
  admin,
  supervisor,
  teacher,
  unknown;

  static AdminRole fromApi(String? value) {
    switch (value) {
      case 'SUPER_ADMIN':
        return AdminRole.superAdmin;
      case 'ADMIN':
        return AdminRole.admin;
      case 'SUPERVISOR':
        return AdminRole.supervisor;
      case 'TEACHER':
        return AdminRole.teacher;
      default:
        return AdminRole.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case AdminRole.superAdmin:
        return 'SUPER_ADMIN';
      case AdminRole.admin:
        return 'ADMIN';
      case AdminRole.supervisor:
        return 'SUPERVISOR';
      case AdminRole.teacher:
        return 'TEACHER';
      case AdminRole.unknown:
        return 'UNKNOWN';
    }
  }

  /// Arabic label for the UI.
  String get labelAr {
    switch (this) {
      case AdminRole.superAdmin:
        return 'مدير عام';
      case AdminRole.admin:
        return 'مدير';
      case AdminRole.supervisor:
        return 'مراقب';
      case AdminRole.teacher:
        return 'معلم';
      case AdminRole.unknown:
        return 'غير معروف';
    }
  }

  bool get isSuperAdmin => this == AdminRole.superAdmin;
  bool get canManageStudents => this == AdminRole.superAdmin || this == AdminRole.admin;
  bool get canAuthorExams =>
      this == AdminRole.superAdmin || this == AdminRole.admin || this == AdminRole.teacher;
  bool get canMonitor =>
      this == AdminRole.superAdmin || this == AdminRole.admin || this == AdminRole.supervisor;
}
