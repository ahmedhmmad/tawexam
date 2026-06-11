// lib/core/di/service_locator.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../constants/api_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/auth_token_store.dart';
import '../network/connectivity_service.dart';
import '../network/token_provider.dart';
import '../storage/local_storage_service.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_service.dart';
import '../timer/countdown_service.dart';

// Admin imports
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/datasources/monitoring_remote_datasource.dart';
import '../../features/admin/data/datasources/monitoring_socket_service.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/create_exam_usecase.dart';
import '../../features/admin/domain/usecases/delete_exam_usecase.dart';
import '../../features/admin/domain/usecases/download_questions_template_usecase.dart';
import '../../features/admin/domain/usecases/export_results_usecase.dart';
import '../../features/admin/domain/usecases/export_students_usecase.dart';
import '../../features/admin/domain/usecases/get_exams_usecase.dart';
import '../../features/admin/domain/usecases/get_results_usecase.dart';
import '../../features/admin/domain/usecases/get_students_usecase.dart';
import '../../features/admin/domain/usecases/import_students_usecase.dart';
import '../../features/admin/domain/usecases/update_exam_usecase.dart';
import '../../features/admin/domain/usecases/update_exam_status_usecase.dart';
import '../../features/admin/domain/usecases/upload_questions_usecase.dart';
import '../../features/admin/presentation/cubit/admin_auth_cubit.dart';
import '../../features/admin/presentation/cubit/monitoring_cubit.dart';
import '../../features/admin/presentation/cubit/exam_manager_cubit.dart';
import '../../features/admin/presentation/cubit/question_upload_cubit.dart';
import '../../features/admin/presentation/cubit/student_manager_cubit.dart';
import '../../features/admin/presentation/cubit/results_cubit.dart';

// Auth imports
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// Exam imports
import '../../features/exam/data/datasources/exam_local_datasource.dart';
import '../../features/exam/data/datasources/exam_remote_datasource.dart';
import '../../features/exam/data/repositories/exam_repository_impl.dart';
import '../../features/exam/domain/repositories/exam_session_repository.dart';
import '../../features/exam/domain/repositories/exam_repository.dart';
import '../../features/exam/domain/usecases/load_exam_usecase.dart';
import '../../features/exam/domain/usecases/load_exam_session_usecase.dart';
import '../../features/exam/domain/usecases/load_questions_usecase.dart';
import '../../features/exam/domain/usecases/restore_exam_progress_usecase.dart';
import '../../features/exam/domain/usecases/save_answer_usecase.dart';
import '../../features/exam/domain/usecases/save_flagged_questions_usecase.dart';
import '../../features/exam/domain/usecases/submit_exam_usecase.dart';
import '../../features/exam/presentation/cubit/exam_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final storage = LocalStorageService();
  await storage.init();

  getIt
    ..registerSingleton<LocalStorageService>(storage)
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton<TokenProvider>(
      () => AuthTokenStore(getIt(), getIt()),
    )
    ..registerLazySingleton(() => AuthInterceptor(
          getIt<TokenProvider>(),
          authDio: Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          )),
        ))
    ..registerLazySingleton(() => ApiClient(getIt<AuthInterceptor>()))
    ..registerLazySingleton(() => Connectivity())
    ..registerLazySingleton(() => ConnectivityService(getIt()))
    ..registerLazySingleton(() => SyncQueue(getIt()))
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt<ApiClient>().dio),
    )
    ..registerLazySingleton<AuthRepository>(
      () =>
          AuthRepositoryImpl(remoteDataSource: getIt(), tokenProvider: getIt()),
    )
    ..registerLazySingleton(() => LoginUseCase(getIt()))
    ..registerFactory(() => AuthCubit(getIt()))
    ..registerLazySingleton<ExamRemoteDataSource>(
      () => ExamRemoteDataSourceImpl(getIt<ApiClient>().dio),
    )
    ..registerLazySingleton<ExamLocalDataSource>(
      () => ExamLocalDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ExamRepository>(
      () => ExamRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
        syncService: getIt(),
      ),
    )
    ..registerLazySingleton<ExamSessionRepository>(
      () => getIt<ExamRepository>(),
    )
    ..registerLazySingleton(() => LoadExamUseCase(getIt()))
    ..registerLazySingleton(() => LoadExamSessionUseCase(getIt()))
    ..registerLazySingleton(() => LoadQuestionsUseCase(getIt()))
    ..registerLazySingleton(() => RestoreExamProgressUseCase(getIt()))
    ..registerLazySingleton(() => SaveAnswerUseCase(getIt()))
    ..registerLazySingleton(() => SaveFlaggedQuestionsUseCase(getIt()))
    ..registerLazySingleton(() => SubmitExamUseCase(getIt()))
    ..registerFactory(
      () => ExamCubit(
        loadExamUseCase: getIt(),
        loadExamSessionUseCase: getIt(),
        loadQuestionsUseCase: getIt(),
        restoreProgressUseCase: getIt(),
        saveAnswerUseCase: getIt(),
        saveFlaggedQuestionsUseCase: getIt(),
        submitExamUseCase: getIt(),
        countdownService: getIt(),
      ),
    )
    ..registerLazySingleton(
      () => SyncService(
        queue: getIt(),
        connectivityService: getIt(),
        dio: getIt<ApiClient>().dio,
      ),
    )
    // Admin registrations
    ..registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSourceImpl(getIt<ApiClient>().dio),
    )
    ..registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetExamsUseCase(getIt()))
    ..registerLazySingleton(() => CreateExamUseCase(getIt()))
    ..registerLazySingleton(() => UpdateExamUseCase(getIt()))
    ..registerLazySingleton(() => UpdateExamStatusUseCase(getIt()))
    ..registerLazySingleton(() => DeleteExamUseCase(getIt()))
    ..registerLazySingleton(() => GetStudentsUseCase(getIt()))
    ..registerLazySingleton(() => ImportStudentsUseCase(getIt()))
    ..registerLazySingleton(() => ExportStudentsUseCase(getIt()))
    ..registerLazySingleton(() => UploadQuestionsUseCase(getIt()))
    ..registerLazySingleton(() => DownloadQuestionsTemplateUseCase(getIt()))
    ..registerLazySingleton(() => GetResultsUseCase(getIt()))
    ..registerLazySingleton(() => ExportResultsUseCase(getIt()))
    ..registerFactory(() => AdminAuthCubit(getIt<ApiClient>(), getIt<TokenProvider>()))
    ..registerFactory(() => ExamManagerCubit(
          getExams: getIt(),
          createExam: getIt(),
          updateExam: getIt(),
          updateStatus: getIt(),
          deleteExam: getIt(),
        ))
    ..registerFactory(() => QuestionUploadCubit(getIt()))
    ..registerFactory(() => StudentManagerCubit(
          getStudents: getIt(),
          importStudents: getIt(),
          exportStudents: getIt(),
        ))
    ..registerFactory(() => ResultsCubit(
          getResults: getIt(),
          exportResults: getIt(),
        ))
    ..registerLazySingleton<MonitoringRemoteDataSource>(
      () => MonitoringRemoteDataSourceImpl(getIt<ApiClient>().dio),
    )
    ..registerFactory(() => MonitoringCubit(
          dataSource: getIt(),
          // New socket per cubit: connection lifecycle follows the page
          socketService: MonitoringSocketServiceImpl(getIt<TokenProvider>()),
        ))
    ..registerSingleton<CountdownService>(CountdownService.instance);

  getIt<CountdownService>().attachStorage(storage);
  await getIt<ConnectivityService>().start();
  await getIt<SyncService>().start();
}
