import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/auth_token_store.dart';
import '../network/connectivity_service.dart';
import '../network/token_provider.dart';
import '../storage/local_storage_service.dart';
import '../sync/sync_queue.dart';
import '../sync/sync_service.dart';
import '../timer/countdown_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/exam/data/datasources/exam_local_datasource.dart';
import '../../features/exam/data/datasources/exam_remote_datasource.dart';
import '../../features/exam/data/repositories/exam_repository_impl.dart';
import '../../features/exam/domain/repositories/exam_repository.dart';
import '../../features/exam/domain/usecases/load_exam_usecase.dart';
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
    ..registerLazySingleton<TokenProvider>(() => AuthTokenStore(getIt()))
    ..registerLazySingleton(() => AuthInterceptor(getIt()))
    ..registerLazySingleton(() => ApiClient(getIt()))
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
    ..registerLazySingleton(() => LoadExamUseCase(getIt()))
    ..registerLazySingleton(() => LoadQuestionsUseCase(getIt()))
    ..registerLazySingleton(() => RestoreExamProgressUseCase(getIt()))
    ..registerLazySingleton(() => SaveAnswerUseCase(getIt()))
    ..registerLazySingleton(() => SaveFlaggedQuestionsUseCase(getIt()))
    ..registerLazySingleton(() => SubmitExamUseCase(getIt()))
    ..registerFactory(
      () => ExamCubit(
        loadExamUseCase: getIt(),
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
    ..registerSingleton<CountdownService>(CountdownService.instance);

  getIt<CountdownService>().attachStorage(storage);
  await getIt<ConnectivityService>().start();
  await getIt<SyncService>().start();
}
