import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/network/token_provider.dart';
import 'core/storage/local_storage_service.dart';
import 'features/auth/domain/entities/student.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/exam/presentation/cubit/exam_cubit.dart';
import 'features/exam/presentation/pages/student_home_page.dart';

const _studentCacheKey = 'cached_student';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Background sync - no-op for now
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Show splash immediately while initializing
  runApp(const _LoadingApp());
  await configureDependencies();
  // Check for saved session
  final savedStudent = await _loadCachedStudent();
  runApp(TawExamApp(savedStudent: savedStudent));
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 96, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'توجيهي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'منصة الامتحانات',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
