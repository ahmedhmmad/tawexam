import 'package:dio/dio.dart';

import '../../domain/entities/activity_event.dart';

class ActivityPage {
  const ActivityPage({required this.rows, required this.total});
  final List<ActivityEvent> rows;
  final int total;
}

abstract interface class ActivityRemoteDataSource {
  Future<ActivityPage> list({
    String? examId,
    String? studentId,
    String? eventType,
    DateTime? from,
    DateTime? to,
    int page,
    int limit,
  });
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  const ActivityRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ActivityPage> list({
    String? examId,
    String? studentId,
    String? eventType,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/admin/activity', queryParameters: {
      if (examId != null && examId.isNotEmpty) 'examId': examId,
      if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      if (eventType != null && eventType.isNotEmpty) 'eventType': eventType,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    final data = Map<String, dynamic>.from(r.data?['data'] as Map? ?? {});
    final rows = (data['rows'] as List? ?? [])
        .map((e) => ActivityEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return ActivityPage(rows: rows, total: (data['total'] as num?)?.toInt() ?? rows.length);
  }
}
