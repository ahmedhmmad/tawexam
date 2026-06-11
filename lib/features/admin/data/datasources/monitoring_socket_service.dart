import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/constants/api_config.dart';
import '../../../../core/network/token_provider.dart';

enum MonitoringConnectionStatus { connecting, connected, disconnected }

/// A live event from the backend's /admin/monitoring namespace.
class MonitoringEvent {
  const MonitoringEvent(this.type, this.payload);

  /// 'session:started' | 'answer:saved' | 'session:ended'
  final String type;
  final Map<String, dynamic> payload;
}

/// Wraps the Socket.IO connection to the admin monitoring namespace.
/// Reconnects automatically with exponential backoff and exposes the
/// connection state + events as streams, so the cubit stays socket-agnostic.
abstract interface class MonitoringSocketService {
  Stream<MonitoringConnectionStatus> get connectionStatus;
  Stream<MonitoringEvent> get events;
  Future<void> connect();
  Future<void> dispose();
}

class MonitoringSocketServiceImpl implements MonitoringSocketService {
  MonitoringSocketServiceImpl(this._tokenProvider);

  final TokenProvider _tokenProvider;
  io.Socket? _socket;

  final _statusController = StreamController<MonitoringConnectionStatus>.broadcast();
  final _eventsController = StreamController<MonitoringEvent>.broadcast();

  static const _monitoredEvents = ['session:started', 'answer:saved', 'session:ended'];

  @override
  Stream<MonitoringConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  Stream<MonitoringEvent> get events => _eventsController.stream;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    final token = await _tokenProvider.readAccessToken() ?? '';

    _statusController.add(MonitoringConnectionStatus.connecting);
    final socket = io.io(
      '${ApiConfig.serverOrigin}/admin/monitoring',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          // Exponential backoff: 1s base doubling (randomized) up to 30s,
          // retrying indefinitely until dispose().
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(30000)
          .setRandomizationFactor(0.5)
          .enableReconnection()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) => _statusController.add(MonitoringConnectionStatus.connected));
    socket.onDisconnect((_) => _statusController.add(MonitoringConnectionStatus.disconnected));
    socket.onReconnectAttempt((_) => _statusController.add(MonitoringConnectionStatus.connecting));
    socket.onConnectError((_) => _statusController.add(MonitoringConnectionStatus.disconnected));

    for (final eventName in _monitoredEvents) {
      socket.on(eventName, (dynamic data) {
        final payload = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        _eventsController.add(MonitoringEvent(eventName, payload));
      });
    }

    socket.connect();
  }

  @override
  Future<void> dispose() async {
    _socket?.dispose();
    _socket = null;
    await _statusController.close();
    await _eventsController.close();
  }
}
