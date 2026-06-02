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
