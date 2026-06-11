import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/features/admin/data/datasources/monitoring_remote_datasource.dart';
import 'package:taw_exam/features/admin/data/datasources/monitoring_socket_service.dart';
import 'package:taw_exam/features/admin/data/models/live_session_model.dart';
import 'package:taw_exam/features/admin/presentation/cubit/monitoring_cubit.dart';
import 'package:taw_exam/features/admin/presentation/cubit/monitoring_state.dart';

class _FakeDataSource implements MonitoringRemoteDataSource {
  _FakeDataSource(this.responses);

  final List<Object> responses; // List<LiveSessionModel> or Exception
  int calls = 0;

  @override
  Future<List<LiveSessionModel>> fetchActiveSessions() async {
    final response = responses[calls.clamp(0, responses.length - 1)];
    calls++;
    if (response is Exception) throw response;
    return response as List<LiveSessionModel>;
  }
}

class _FakeSocketService implements MonitoringSocketService {
  final statusController = StreamController<MonitoringConnectionStatus>.broadcast();
  final eventsController = StreamController<MonitoringEvent>.broadcast();
  bool connected = false;
  bool disposed = false;

  @override
  Stream<MonitoringConnectionStatus> get connectionStatus => statusController.stream;

  @override
  Stream<MonitoringEvent> get events => eventsController.stream;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> dispose() async {
    disposed = true;
    await statusController.close();
    await eventsController.close();
  }
}

LiveSessionModel session(String id, {int answered = 0}) {
  final now = DateTime.now();
  return LiveSessionModel(
    sessionId: id,
    examId: 'exam1',
    examName: 'رياضيات',
    studentName: 'طالب $id',
    seatNumber: '10000$id',
    branch: 'علمي',
    attemptNumber: 1,
    startedAt: now,
    expiresAt: now.add(const Duration(minutes: 30)),
    answeredCount: answered,
    status: 'IN_PROGRESS',
  );
}

void main() {
  group('MonitoringCubit', () {
    late _FakeSocketService socket;

    setUp(() => socket = _FakeSocketService());

    blocTest<MonitoringCubit, MonitoringState>(
      'emits Ready with sessions after start',
      build: () => MonitoringCubit(
        dataSource: _FakeDataSource([
          [session('1'), session('2')],
        ]),
        socketService: socket,
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<MonitoringLoading>(),
        isA<MonitoringReady>().having((s) => s.sessions.length, 'sessions', 2),
      ],
      verify: (_) => expect(socket.connected, isTrue),
    );

    blocTest<MonitoringCubit, MonitoringState>(
      'emits Error with a friendly message when the snapshot fails',
      build: () => MonitoringCubit(
        dataSource: _FakeDataSource([Exception('boom')]),
        socketService: socket,
      ),
      act: (cubit) => cubit.start(),
      expect: () => [
        isA<MonitoringLoading>(),
        isA<MonitoringError>().having(
          (s) => s.message,
          'message',
          isNot(contains('boom')), // raw exception text never reaches the UI
        ),
      ],
    );

    blocTest<MonitoringCubit, MonitoringState>(
      'answer:saved bumps the count once per question (dedupe)',
      build: () => MonitoringCubit(
        dataSource: _FakeDataSource([
          [session('1', answered: 3)],
        ]),
        socketService: socket,
      ),
      act: (cubit) async {
        await cubit.start();
        socket.eventsController
          ..add(const MonitoringEvent('answer:saved', {'sessionId': '1', 'questionId': 'q9'}))
          ..add(const MonitoringEvent('answer:saved', {'sessionId': '1', 'questionId': 'q9'}));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<MonitoringLoading>(),
        isA<MonitoringReady>().having((s) => s.sessions.single.answeredCount, 'count', 3),
        isA<MonitoringReady>().having((s) => s.sessions.single.answeredCount, 'count', 4),
      ],
    );

    blocTest<MonitoringCubit, MonitoringState>(
      'session:started triggers a snapshot refresh (coalesced)',
      build: () => MonitoringCubit(
        dataSource: _FakeDataSource([
          [session('1')],
          [session('1'), session('2')],
        ]),
        socketService: socket,
      ),
      act: (cubit) async {
        await cubit.start();
        socket.eventsController
            .add(const MonitoringEvent('session:started', {'sessionId': '2'}));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        isA<MonitoringLoading>(),
        isA<MonitoringReady>().having((s) => s.sessions.length, 'sessions', 1),
        isA<MonitoringReady>().having((s) => s.sessions.length, 'sessions', 2),
      ],
    );

    blocTest<MonitoringCubit, MonitoringState>(
      'connection status changes are reflected in the Ready state',
      build: () => MonitoringCubit(
        dataSource: _FakeDataSource([
          [session('1')],
        ]),
        socketService: socket,
      ),
      act: (cubit) async {
        await cubit.start();
        socket.statusController.add(MonitoringConnectionStatus.disconnected);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<MonitoringLoading>(),
        isA<MonitoringReady>(),
        isA<MonitoringReady>().having(
          (s) => s.connection,
          'connection',
          MonitoringConnectionStatus.disconnected,
        ),
      ],
    );

    test('close disposes the socket service', () async {
      final cubit = MonitoringCubit(
        dataSource: _FakeDataSource([<LiveSessionModel>[]]),
        socketService: socket,
      );
      await cubit.close();
      expect(socket.disposed, isTrue);
    });
  });
}
