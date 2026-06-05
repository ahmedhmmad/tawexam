import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/network/token_provider.dart';
import 'core/di/service_locator.dart';
import 'features/admin/presentation/cubit/admin_auth_cubit.dart';
import 'features/admin/presentation/pages/admin_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await configureDependencies();
  } catch (_) {
    // Some services (Workmanager, ConnectivityPlus) may not work on web
    // but GetIt is still registered with the core dependencies
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
        create: (_) => getIt<AdminAuthCubit>(),
        child: const AdminLoginPage(),
      ),
    );
  }
}
