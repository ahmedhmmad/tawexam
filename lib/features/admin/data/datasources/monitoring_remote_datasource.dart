import 'package:dio/dio.dart';

import '../models/live_session_model.dart';

abstract interface class MonitoringRemoteDataSource {
  Future<List<LiveSessionModel>> fetchActiveSessions();
}

class MonitoringRemoteDataSourceImpl implements MonitoringRemoteDataSource {
  const MonitoringRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<LiveSessionModel>> fetchActiveSessions() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/monitoring/active-sessions',
    );
    final data = response.data?['data'];
    if (data is! List) return const [];
    return data
        .map((row) => LiveSessionModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }
}
