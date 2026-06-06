import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'core/di/service_locator.dart';
import 'core/network/token_provider.dart';
import 'core/storage/local_storage_service.dart';
import 'core/sync/sync_service.dart';
import 'features/auth/domain/entities/student.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/exam/presentation/cubit/exam_cubit.dart';
import 'features/exam/presentation/pages/student_home_page.dart';

const _syncTaskName = 'com.tawexam.backgroundSync';
const _studentCacheKey = 'cached_student';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == _syncTaskName || task == Workmanager.iOSBackgroundTask) {
      try {
        final service = getIt<SyncService>();
        await service.syncPending();
      } catch (_) {}
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

  // Check for saved session
  final savedStudent = await _loadCachedStudent();
  runApp(TawExamApp(savedStudent: savedStudent));
}

/// Try to load cached student from local storage (session persistence)
Future<Student?> _loadCachedStudent() async {
  try {
    final tokenProvider = getIt<TokenProvider>();
    final token = await tokenProvider.readAccessToken();
    if (token == null || token.isEmpty) return null;

    final storage = getIt<LocalStorageService>();
    final cached = await storage.read<Map<dynamic, dynamic>>('auth_box', _studentCacheKey);
    if (cached == null) return null;

    return Student(
      id: cached['id'] as String? ?? '',
      seatNumber: cached['seatNumber'] as String? ?? '',
      fullName: cached['fullName'] as String? ?? '',
      branch: cached['branch'] as String? ?? '',
      schoolName: cached['schoolName'] as String? ?? '',
    );
  } catch (_) {
    return null;
  }
}

/// Save student info locally for session persistence
Future<void> cacheStudent(Student student) async {
  try {
    final storage = getIt<LocalStorageService>();
    await storage.write('auth_box', _studentCacheKey, {
      'id': student.id,
      'seatNumber': student.seatNumber,
      'fullName': student.fullName,
      'branch': student.branch,
      'schoolName': student.schoolName,
    });
  } catch (_) {}
}

class TawExamApp extends StatelessWidget {
  const TawExamApp({super.key, this.homeOverride, this.savedStudent});

  final Widget? homeOverride;
  final Student? savedStudent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TawExam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: homeOverride ?? _buildHome(),
    );
  }

  Widget _buildHome() {
    // If student was previously logged in, go directly to home
    if (savedStudent != null) {
      final examCubit = getIt<ExamCubit>();
      examCubit.loadForStudent(student: savedStudent!);
      return BlocProvider.value(
        value: examCubit,
        child: StudentHomePage(student: savedStudent!),
      );
    }
    // Otherwise show login
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: const LoginPage(),
    );
  }
}
