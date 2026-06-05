import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/connectivity_service.dart';

class ConnectivityIndicator extends StatefulWidget {
  const ConnectivityIndicator({super.key});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  final ConnectivityService _service = getIt<ConnectivityService>();
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _service.isOnline.then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _subscription = _service.onStatusChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOnline
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            size: 14,
            color: _isOnline ? Colors.green.shade800 : Colors.red.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'متصل' : 'غير متصل',
            style: TextStyle(
              fontSize: 11,
              color: _isOnline ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
