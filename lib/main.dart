import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'core/di/service_locator.dart';
import 'core/sync/sync_service.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';

const _syncTaskName = 'com.tawexam.backgroundSync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _syncTaskName || task == Workmanager.iOSBackgroundTask) {
      try {
        final service = getIt<SyncService>();
        await service.syncPending();
      } catch (_) {
        // Swallow errors in background — will retry next cycle
      }
    }
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    _syncTaskName,
    _syncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
  runApp(const TawExamApp());
}

class TawExamApp extends StatelessWidget {
  const TawExamApp({super.key, this.homeOverride});

  final Widget? homeOverride;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TawExam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: homeOverride ?? _buildLoginPage(),
    );
  }

  Widget _buildLoginPage() {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const LoginPage(),
    );
  }
}
