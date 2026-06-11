// lib/features/admin/presentation/pages/admin_shell_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/admin_auth_cubit.dart';
import '../cubit/admin_auth_state.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/student_manager_cubit.dart';
import '../cubit/monitoring_cubit.dart';
import 'admin_login_page.dart';
import 'admin_results_overview_page.dart';
import 'exams_list_page.dart';
import 'monitoring_page.dart';
import 'students_page.dart';

class _AdminAuthGate extends StatelessWidget {
  const _AdminAuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAuthCubit, AdminAuthState>(
      builder: (ctx, state) {
        if (state is AdminAuthSuccess) return const AdminShellPage();
        return const AdminLoginPage();
      },
    );
  }
}

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  static const _destinations = [
    NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('الامتحانات')),
    NavigationRailDestination(icon: Icon(Icons.people), label: Text('الطلاب')),
    NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('النتائج')),
    NavigationRailDestination(icon: Icon(Icons.podcasts), label: Text('مراقبة مباشرة')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AdminAuthCubit>().logout();
                      if (!context.mounted) return;
                      // Force rebuild to ensure login page shows
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AdminAuthCubit>(),
                            child: const _AdminAuthGate(),
                          ),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_index) {
      case 0:
        return BlocProvider(
          create: (_) => getIt<ExamManagerCubit>()..load(),
          child: const ExamsListContent(),
        );
      case 1:
        return BlocProvider(
          create: (_) => getIt<StudentManagerCubit>()..load(),
          child: const StudentsContent(),
        );
      case 2:
        return BlocProvider(
          create: (_) => getIt<ExamManagerCubit>()..load(),
          child: const AdminResultsOverviewPage(),
        );
      default:
        return BlocProvider(
          create: (_) => getIt<MonitoringCubit>()..start(),
          child: const MonitoringContent(),
        );
    }
  }
}
