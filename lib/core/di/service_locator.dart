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
