import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/features/admin/domain/entities/admin_role.dart';

void main() {
  group('AdminRole.fromApi', () {
    test('maps backend enum strings', () {
      expect(AdminRole.fromApi('SUPER_ADMIN'), AdminRole.superAdmin);
      expect(AdminRole.fromApi('ADMIN'), AdminRole.admin);
      expect(AdminRole.fromApi('SUPERVISOR'), AdminRole.supervisor);
      expect(AdminRole.fromApi('TEACHER'), AdminRole.teacher);
    });

    test('falls back to unknown for null / unrecognized', () {
      expect(AdminRole.fromApi(null), AdminRole.unknown);
      expect(AdminRole.fromApi('EXAM_MANAGER'), AdminRole.unknown);
      expect(AdminRole.fromApi(''), AdminRole.unknown);
    });

    test('round-trips through apiValue', () {
      for (final role in [
        AdminRole.superAdmin,
        AdminRole.admin,
        AdminRole.supervisor,
        AdminRole.teacher,
      ]) {
        expect(AdminRole.fromApi(role.apiValue), role);
      }
    });
  });

  group('permission helpers (drive nav gating)', () {
    test('student management is admin/super-admin only', () {
      expect(AdminRole.superAdmin.canManageStudents, isTrue);
      expect(AdminRole.admin.canManageStudents, isTrue);
      expect(AdminRole.supervisor.canManageStudents, isFalse);
      expect(AdminRole.teacher.canManageStudents, isFalse);
    });

    test('exam authoring excludes supervisor', () {
      expect(AdminRole.superAdmin.canAuthorExams, isTrue);
      expect(AdminRole.admin.canAuthorExams, isTrue);
      expect(AdminRole.teacher.canAuthorExams, isTrue);
      expect(AdminRole.supervisor.canAuthorExams, isFalse);
    });

    test('monitoring excludes teacher', () {
      expect(AdminRole.superAdmin.canMonitor, isTrue);
      expect(AdminRole.admin.canMonitor, isTrue);
      expect(AdminRole.supervisor.canMonitor, isTrue);
      expect(AdminRole.teacher.canMonitor, isFalse);
    });

    test('only super admin manages users', () {
      expect(AdminRole.superAdmin.isSuperAdmin, isTrue);
      expect(AdminRole.admin.isSuperAdmin, isFalse);
    });
  });
}
