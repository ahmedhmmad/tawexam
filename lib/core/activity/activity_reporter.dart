import 'dart:async';

import 'package:dio/dio.dart';

/// Fire-and-forget client-side activity reporting. Posts events to /activity
/// using the authenticated Dio client. Never throws and never blocks the UI —
/// a logging failure must not affect the exam flow.
class ActivityReporter {
  const ActivityReporter(this._dio);

  final Dio _dio;

  void report(
    String eventType, {
    String? examId,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    unawaited(() async {
      try {
        await _dio.post<void>('/activity', data: {
          'eventType': eventType,
          if (examId != null) 'examId': examId,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
        });
      } catch (_) {
        // best effort — ignore (offline, 401, etc.)
      }
    }());
  }
}

/// Client-reportable event types (must match the backend whitelist).
class ClientActivityEvent {
  const ClientActivityEvent._();
  static const examOpened = 'EXAM_OPENED';
  static const appBackgrounded = 'APP_BACKGROUNDED';
  static const appForegrounded = 'APP_FOREGROUNDED';
  static const internetDisconnected = 'INTERNET_DISCONNECTED';
  static const internetRestored = 'INTERNET_RESTORED';
  static const syncQueued = 'SYNC_QUEUED';
  static const syncCompleted = 'SYNC_COMPLETED';
  static const sessionResumed = 'SESSION_RESUMED';
}
