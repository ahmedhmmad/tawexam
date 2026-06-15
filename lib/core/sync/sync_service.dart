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

  /// Drains every task in order. Crucially, one failing task must NOT block the
  /// rest of the queue — a poison answer (e.g. for a question the admin later
  /// deleted) used to stall the queue forever and prevent the final exam submit
  /// from ever reaching the server, leaving the session stuck IN_PROGRESS.
  Future<void> _drainQueue() async {
    var allCleared = true;
    for (final task in await _queue.pendingTasks()) {
      final outcome = await _syncTask(task);
      // Keep going on every outcome; only "transient" leaves work pending.
      if (outcome == _SyncOutcome.transient) allCleared = false;
    }
    _status.add(allCleared ? SyncStatus.synced : SyncStatus.offline);
  }

  Future<_SyncOutcome> _syncTask(SyncTask task) async {
    try {
      await _dio.post<dynamic>(task.endpoint, data: task.payload);
      await _queue.remove(task.id);
      return _SyncOutcome.success;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final isSubmit = task.endpoint.contains('/submit');

      // A 4xx (except throttling/timeout) means the request will never succeed
      // — e.g. answer for a deleted question (FK), or validation. Drop it so it
      // can't block the queue. The final submit carries all answers anyway.
      final permanent =
          status != null && status >= 400 && status < 500 && status != 408 && status != 429;
      if (permanent && !isSubmit) {
        await _queue.remove(task.id);
        return _SyncOutcome.dropped;
      }

      // Transient (offline / 5xx / timeout / throttled). Count attempts and
      // give up on non-critical answer tasks after the cap; the submit task is
      // never dropped — grading the exam matters more than queue tidiness.
      final attempts = task.attempts + 1;
      if (!isSubmit && attempts >= SyncConstants.maxAttempts) {
        await _queue.remove(task.id);
        return _SyncOutcome.dropped;
      }
      await _queue.replace(task.copyWith(attempts: attempts));
      return _SyncOutcome.transient;
    } catch (_) {
      return _SyncOutcome.transient;
    }
  }

  void _handleConnectivity(bool isOnline) {
    if (isOnline) {
      unawaited(syncPending());
    } else {
      _status.add(SyncStatus.offline);
    }
  }
}

enum _SyncOutcome {
  /// Sent and removed from the queue.
  success,

  /// Permanently rejected (or gave up) and removed — does not block the queue.
  dropped,

  /// Temporary failure; kept for a later retry.
  transient,
}
