import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../data/datasources/monitoring_remote_datasource.dart';
import '../../data/datasources/monitoring_socket_service.dart';
import 'monitoring_state.dart';

/// Live exam monitoring: a REST snapshot of active sessions kept fresh by
/// Socket.IO deltas.
///
/// - session:started / session:ended → refetch the snapshot (events carry
///   only ids; the snapshot has the display data)
/// - answer:saved → bump the row's answered count in place, deduplicated by
///   questionId so re-answering the same question doesn't inflate the count
class MonitoringCubit extends Cubit<MonitoringState> {
  MonitoringCubit({
    required MonitoringRemoteDataSource dataSource,
    required MonitoringSocketService socketService,
  }) : _dataSource = dataSource,
       _socketService = socketService,
       super(const MonitoringLoading());

  final MonitoringRemoteDataSource _dataSource;
  final MonitoringSocketService _socketService;

  StreamSubscription<MonitoringConnectionStatus>? _statusSubscription;
  StreamSubscription<MonitoringEvent>? _eventsSubscription;

  /// questionIds already counted per session (answer:saved dedupe).
  final Map<String, Set<String>> _countedAnswers = {};
  MonitoringConnectionStatus _connection = MonitoringConnectionStatus.connecting;
  bool _refreshScheduled = false;

  Future<void> start() async {
    _statusSubscription ??= _socketService.connectionStatus.listen(_onConnectionStatus);
    _eventsSubscription ??= _socketService.events.listen(_onEvent);
    await _socketService.connect();
    await refresh();
  }

  Future<void> refresh() async {
    if (state is! MonitoringReady) emit(const MonitoringLoading());
    try {
      final sessions = await _dataSource.fetchActiveSessions();
      _countedAnswers.removeWhere(
        (sessionId, _) => !sessions.any((s) => s.sessionId == sessionId),
      );
      emit(MonitoringReady(sessions: sessions, connection: _connection));
    } catch (error) {
      emit(MonitoringError(mapExceptionToFailure(error).message));
    }
  }

  void _onConnectionStatus(MonitoringConnectionStatus status) {
    final wasDisconnected = _connection != MonitoringConnectionStatus.connected;
    _connection = status;
    final current = state;
    if (current is MonitoringReady) {
      emit(current.copyWith(connection: status));
    }
    // Catch up on anything missed while offline
    if (status == MonitoringConnectionStatus.connected && wasDisconnected) {
      _scheduleRefresh();
    }
  }

  void _onEvent(MonitoringEvent event) {
    switch (event.type) {
      case 'session:started':
      case 'session:ended':
        _scheduleRefresh();
      case 'answer:saved':
        _applyAnswerSaved(event.payload);
    }
  }

  void _applyAnswerSaved(Map<String, dynamic> payload) {
    final current = state;
    if (current is! MonitoringReady) return;
    final sessionId = '${payload['sessionId'] ?? ''}';
    final questionId = '${payload['questionId'] ?? ''}';
    if (sessionId.isEmpty || questionId.isEmpty) return;

    final counted = _countedAnswers.putIfAbsent(sessionId, () => <String>{});
    if (!counted.add(questionId)) return; // already counted this question

    final sessions = current.sessions
        .map(
          (session) => session.sessionId == sessionId
              ? session.copyWith(answeredCount: session.answeredCount + 1)
              : session,
        )
        .toList(growable: false);
    emit(current.copyWith(sessions: sessions));
  }

  /// Coalesces bursts of events into a single snapshot fetch.
  void _scheduleRefresh() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      _refreshScheduled = false;
      if (!isClosed) refresh();
    });
  }

  @override
  Future<void> close() async {
    await _statusSubscription?.cancel();
    await _eventsSubscription?.cancel();
    await _socketService.dispose();
    return super.close();
  }
}
