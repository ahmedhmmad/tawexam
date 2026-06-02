import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/sync_constants.dart';
import '../network/connectivity_service.dart';
import 'sync_queue.dart';
import 'sync_status.dart';
import 'sync_task.dart';

class SyncService {
  SyncService({
    required SyncQueue queue,
    required ConnectivityService connectivityService,
    required Dio dio,
  }) : _queue = queue,
       _connectivityService = connectivityService,
       _dio = dio;

  final SyncQueue _queue;
  final ConnectivityService _connectivityService;
  final Dio _dio;
  final StreamController<SyncStatus> _status = StreamController.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isRunning = false;

  Stream<SyncStatus> get status => _status.stream;

  Future<void> start() async {
    _connectivitySubscription ??= _connectivityService.onStatusChanged.listen(
      _handleConnectivity,
    );
    if (await _connectivityService.isOnline) {
      await syncPending();
    }
  }

  Future<void> enqueue(SyncTask task) async {
    await _queue.enqueue(task);
    if (await _connectivityService.isOnline) {
      await syncPending();
    }
  }

  Future<void> syncPending() async {
    if (_isRunning) return;
    _isRunning = true;
    _status.add(SyncStatus.syncing);
    await _drainQueue();
    _isRunning = false;
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _status.close();
  }

  Future<void> _drainQueue() async {
    for (final task in await _queue.pendingTasks()) {
      final didSync = await _syncTask(task);
      if (!didSync) return;
    }
    _status.add(SyncStatus.synced);
  }

  Future<bool> _syncTask(SyncTask task) async {
    try {
      await _dio.post<dynamic>(task.endpoint, data: task.payload);
      await _queue.remove(task.id);
      return true;
    } on DioException {
      await _handleFailedTask(task);
      return false;
    }
  }

  Future<void> _handleFailedTask(SyncTask task) async {
    final attempts = task.attempts + 1;
    if (attempts >= SyncConstants.maxAttempts) {
      _status.add(SyncStatus.failed);
      return;
    }
    await _queue.replace(task.copyWith(attempts: attempts));
    _status.add(SyncStatus.offline);
    await Future<void>.delayed(_retryDelay(attempts));
  }

  Duration _retryDelay(int attempts) {
    return SyncConstants.retryBaseDelay * attempts;
  }

  void _handleConnectivity(bool isOnline) {
    if (isOnline) {
      unawaited(syncPending());
    } else {
      _status.add(SyncStatus.offline);
    }
  }
}
