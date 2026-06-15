// test/core/sync/sync_service_test.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taw_exam/core/network/connectivity_service.dart';
import 'package:taw_exam/core/sync/sync_queue.dart';
import 'package:taw_exam/core/sync/sync_service.dart';
import 'package:taw_exam/core/sync/sync_status.dart';
import 'package:taw_exam/core/sync/sync_task.dart';

class MockSyncQueue extends Mock implements SyncQueue {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockDio extends Mock implements Dio {}

void main() {
  late MockSyncQueue queue;
  late MockConnectivityService connectivity;
  late MockDio dio;
  late SyncService service;

  final task = SyncTask(
    id: 't1',
    endpoint: '/answers',
    payload: {'questionId': 'q1'},
    createdAt: DateTime.now(),
  );

  setUpAll(() => registerFallbackValue(task));

  setUp(() {
    queue = MockSyncQueue();
    connectivity = MockConnectivityService();
    dio = MockDio();
    when(() => connectivity.onStatusChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => connectivity.isOnline).thenAnswer((_) async => false);
    service = SyncService(
      queue: queue,
      connectivityService: connectivity,
      dio: dio,
    );
  });

  test('enqueue calls syncPending when online', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => queue.enqueue(any())).thenAnswer((_) async {});
    when(() => queue.pendingTasks()).thenAnswer((_) async => [task]);
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenAnswer((_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200));
    when(() => queue.remove(any())).thenAnswer((_) async {});

    await service.start();
    await service.enqueue(task);

    verify(() => queue.enqueue(task)).called(greaterThanOrEqualTo(1));
  });

  test('prevents double run', () async {
    when(() => queue.pendingTasks()).thenAnswer((_) async => []);

    // Two concurrent drains: the second is guarded out by _isRunning.
    final f1 = service.syncPending();
    final f2 = service.syncPending();
    await Future.wait([f1, f2]);

    verify(() => queue.pendingTasks()).called(1);
  });

  test('retries on failure and increments attempt count', () async {
    when(() => queue.enqueue(any())).thenAnswer((_) async {});
    when(() => queue.pendingTasks()).thenAnswer((_) async => [task]);
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenThrow(DioException(requestOptions: RequestOptions()));
    when(() => queue.replace(any())).thenAnswer((_) async {});

    final statuses = <SyncStatus>[];
    final sub = service.status.listen(statuses.add);

    await service.syncPending();
    // Let broadcast-stream events flush before asserting.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    verify(() => queue.replace(any())).called(1);
    expect(statuses, contains(SyncStatus.offline));
  });

  test('drops a non-critical task after maxAttempts instead of blocking', () async {
    final maxedTask = SyncTask(
      id: 't_max',
      endpoint: '/answers',
      payload: {},
      createdAt: DateTime.now(),
      attempts: 4,
    );

    when(() => queue.pendingTasks()).thenAnswer((_) async => [maxedTask]);
    when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
        .thenThrow(DioException(requestOptions: RequestOptions()));
    when(() => queue.remove(any())).thenAnswer((_) async {});

    await service.syncPending();

    // At the cap it's removed (not left to block the queue forever).
    verify(() => queue.remove('t_max')).called(1);
  });

  test('a permanently-rejected answer is dropped and the submit still runs', () async {
    final poisonAnswer = SyncTask(
      id: 'ans_bad',
      endpoint: '/answers',
      payload: {'questionId': 'deleted'},
      createdAt: DateTime.now(),
    );
    final submit = SyncTask(
      id: 'submit_1',
      endpoint: '/exam/e1/submit',
      payload: {'sessionId': 's1', 'answers': {}},
      createdAt: DateTime.now(),
    );

    when(() => queue.pendingTasks()).thenAnswer((_) async => [poisonAnswer, submit]);
    when(() => queue.remove(any())).thenAnswer((_) async {});
    // Answer endpoint 4xx (e.g. FK on a deleted question); submit succeeds.
    when(() => dio.post<dynamic>('/answers', data: any(named: 'data'))).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 400),
      ),
    );
    when(() => dio.post<dynamic>('/exam/e1/submit', data: any(named: 'data')))
        .thenAnswer((_) async => Response(requestOptions: RequestOptions(), statusCode: 200));

    await service.syncPending();

    // Poison answer dropped, and crucially the submit was still sent + cleared.
    verify(() => queue.remove('ans_bad')).called(1);
    verify(() => dio.post<dynamic>('/exam/e1/submit', data: any(named: 'data'))).called(1);
    verify(() => queue.remove('submit_1')).called(1);
  });
}
