import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<ConnectivityResult>? _subscription;

  Stream<bool> get onStatusChanged => _controller.stream.distinct();

  Future<void> start() async {
    _subscription ??= _connectivity.onConnectivityChanged.listen(_emitStatus);
    _emitStatus(await _connectivity.checkConnectivity());
  }

  Future<bool> get isOnline async {
    return _hasConnection(await _connectivity.checkConnectivity());
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  void _emitStatus(ConnectivityResult result) {
    if (!_controller.isClosed) {
      _controller.add(_hasConnection(result));
    }
  }

  bool _hasConnection(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}
