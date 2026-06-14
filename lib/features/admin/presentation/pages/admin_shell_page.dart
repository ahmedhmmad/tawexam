// lib/features/admin/presentation/pages/admin_shell_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/admin_role.dart';
import '../cubit/admin_auth_cubit.dart';
import '../cubit/admin_auth_state.dart';
import '../cubit/admin_users_cubit.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/monitoring_cubit.dart';
import '../cubit/results_cubit.dart';
import '../cubit/student_manager_cubit.dart';
import 'admin_results_overview_page.dart';
import 'admin_users_page.dart';
import 'analytics_dashboard_page.dart';
import 'exams_list_page.dart';
import 'monitoring_page.dart';
import 'students_page.dart';

/// One navigation destination + the page it shows, gated by role.
class _Section {
  const _Section({
    required this.icon,
    required this.label,
    required this.roles,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final Set<AdminRole> roles;
  final WidgetBuilder builder;

  bool visibleTo(AdminRole role) => roles.contains(role);
}

final _allSections = <_Section>[
  _Section(
    icon: Icons.assignment,
    label: 'الامتحانات',
    roles: {AdminRole.superAdmin, AdminRole.admin, AdminRole.teacher},
    builder: (_) => BlocProvider(
      create: (_) => getIt<ExamManagerCubit>()..load(),
      child: const ExamsListContent(),
    ),
  ),
  _Section(
    icon: Icons.people,
    label: 'الطلاب',
    roles: {AdminRole.superAdmin, AdminRole.admin},
    builder: (_) => BlocProvider(
      create: (_) => getIt<StudentManagerCubit>()..load(),
      child: const StudentsContent(),
    ),
  ),
  _Section(
    icon: Icons.bar_chart,
    label: 'النتائج',
    roles: {AdminRole.superAdmin, AdminRole.admin, AdminRole.supervisor, AdminRole.teacher},
    builder: (_) => BlocProvider(
      create: (_) => getIt<ExamManagerCubit>()..load(),
      child: const AdminResultsOverviewPage(),
    ),
  ),
  _Section(
    icon: Icons.podcasts,
    label: 'مراقبة مباشرة',
    roles: {AdminRole.superAdmin, AdminRole.admin, AdminRole.supervisor},
    builder: (_) => BlocProvider(
      create: (_) => getIt<MonitoringCubit>()..start(),
      child: const MonitoringContent(),
    ),
  ),
  _Section(
    icon: Icons.insights,
    label: 'الإحصائيات',
    roles: {AdminRole.superAdmin, AdminRole.admin, AdminRole.supervisor, AdminRole.teacher},
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ExamManagerCubit>()..load()),
        BlocProvider(create: (_) => getIt<ResultsCubit>()),
      ],
      child: const AnalyticsDashboardContent(),
    ),
  ),
  _Section(
    icon: Icons.manage_accounts,
    label: 'المستخدمون',
    roles: {AdminRole.superAdmin},
    builder: (_) => BlocProvider(
      create: (_) => getIt<AdminUsersCubit>()..load(),
      child: const AdminUsersContent(),
    ),
  ),
];

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AdminAuthCubit>().state;
    final role = authState is AdminAuthSuccess ? authState.role : AdminRole.unknown;
    final sections = _allSections.where((s) => s.visibleTo(role)).toList();

    if (sections.isEmpty) {
      // A role with no visible sections (e.g. unknown) — only offer logout.
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم'), actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ]),
        body: const Center(child: Text('لا توجد صلاحيات متاحة لحسابك')),
      );
    }

    final selected = _index.clamp(0, sections.length - 1);
    final username = authState is AdminAuthSuccess ? authState.username : '';

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(Icons.school, color: Color(0xFF1E40AF)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 72,
                    child: Text(
                      role.labelAr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (username.isNotEmpty)
                    SizedBox(
                      width: 72,
                      child: Text(
                        username,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            ),
            destinations: sections
                .map((s) => NavigationRailDestination(icon: Icon(s.icon), label: Text(s.label)))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () => _logout(context),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Key by section label so switching tabs rebuilds the page cleanly.
          Expanded(
            child: KeyedSubtree(
              key: ValueKey(sections[selected].label),
              child: Builder(builder: sections[selected].builder),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    // logout() emits AdminAuthInitial; the _AuthGate in main_admin rebuilds to
    // the login page automatically — no manual navigation needed.
    await context.read<AdminAuthCubit>().logout();
  }
}
