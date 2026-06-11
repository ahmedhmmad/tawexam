import 'package:equatable/equatable.dart';

import '../../data/datasources/monitoring_socket_service.dart';
import '../../domain/entities/live_session.dart';

sealed class MonitoringState extends Equatable {
  const MonitoringState();

  @override
  List<Object?> get props => [];
}

class MonitoringLoading extends MonitoringState {
  const MonitoringLoading();
}

class MonitoringError extends MonitoringState {
  const MonitoringError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class MonitoringReady extends MonitoringState {
  const MonitoringReady({
    required this.sessions,
    required this.connection,
  });

  final List<LiveSession> sessions;
  final MonitoringConnectionStatus connection;

  MonitoringReady copyWith({
    List<LiveSession>? sessions,
    MonitoringConnectionStatus? connection,
  }) {
    return MonitoringReady(
      sessions: sessions ?? this.sessions,
      connection: connection ?? this.connection,
    );
  }

  @override
  List<Object?> get props => [sessions, connection];
}
