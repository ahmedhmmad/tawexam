import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'features/admin/presentation/cubit/admin_auth_state.dart';
import 'features/admin/presentation/pages/admin_login_page.dart';
import 'features/admin/presentation/pages/admin_shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await configureDependencies();
  } catch (_) {
    // Some services (Workmanager, ConnectivityPlus) may not work on web
  }
  runApp(const TawExamAdminApp());
}

class TawExamAdminApp extends StatelessWidget {
  const TawExamAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TawExam Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => getIt<AdminAuthCubit>()..checkSession(),
        child: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminAuthCubit, AdminAuthState>(
      listener: (ctx, state) {
        if (state is AdminAuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (ctx, state) {
        if (state is AdminAuthSuccess) {
          return const AdminShellPage();
        }
        return const AdminLoginPage();
      },
    );
  }
}
