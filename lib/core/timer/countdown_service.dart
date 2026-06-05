import 'dart:async';

import '../constants/storage_keys.dart';
import '../storage/local_storage_service.dart';

class CountdownService {
  CountdownService._();

  static final CountdownService instance = CountdownService._();
  static const _tickInterval = Duration(seconds: 1);
  static const _persistEveryTicks = 5;

  final StreamController<Duration> _controller = StreamController.broadcast();
  LocalStorageService? _storage;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  String? _sessionId;
  int _ticksSincePersist = 0;

  Stream<Duration> get remainingStream => _controller.stream;
  Duration get remaining => _remaining;
  bool get isRunning => _timer?.isActive ?? false;

  void attachStorage(LocalStorageService storage) {
    _storage = storage;
  }

  Future<void> start({
    required String sessionId,
    required Duration duration,
    DateTime? startedAt,
    DateTime? serverTime,
  }) async {
    _sessionId = sessionId;
    final restored = await _restoreRemaining(sessionId);

    if (restored != null && restored != Duration.zero) {
      _remaining = restored;
    } else if (startedAt != null && serverTime != null) {
      final elapsed = serverTime.difference(startedAt);
      _remaining = duration - elapsed;
      if (_remaining.isNegative) _remaining = Duration.zero;
    } else {
      _remaining = duration;
    }

    _emit();
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  Future<void> pause() async {
    _timer?.cancel();
    await _persistRemaining();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _remaining = Duration.zero;
    await _persistRemaining();
    _emit();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }

  void _tick() {
    if (_remaining <= _tickInterval) {
      _remaining = Duration.zero;
      _timer?.cancel();
    } else {
      _remaining -= _tickInterval;
    }
    _emit();
    _persistPeriodically();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_remaining);
    }
  }

  void _persistPeriodically() {
    _ticksSincePersist++;
    if (_ticksSincePersist >= _persistEveryTicks ||
        _remaining == Duration.zero) {
      _ticksSincePersist = 0;
      unawaited(_persistRemaining());
    }
  }

  Future<Duration?> _restoreRemaining(String sessionId) async {
    final seconds = await _storage?.read<int>(
      StorageKeys.examBox,
      '${StorageKeys.remainingTimePrefix}$sessionId',
    );
    return seconds == null ? null : Duration(seconds: seconds);
  }

  Future<void> _persistRemaining() async {
    final storage = _storage;
    final sessionId = _sessionId;
    if (storage == null || sessionId == null) return;
    await storage.write(
      StorageKeys.examBox,
      '${StorageKeys.remainingTimePrefix}$sessionId',
      _remaining.inSeconds,
    );
  }
}
