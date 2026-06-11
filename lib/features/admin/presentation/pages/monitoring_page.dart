// lib/features/admin/presentation/pages/monitoring_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/datasources/monitoring_socket_service.dart';
import '../../domain/entities/live_session.dart';
import '../cubit/monitoring_cubit.dart';
import '../cubit/monitoring_state.dart';

class MonitoringContent extends StatefulWidget {
  const MonitoringContent({super.key});

  @override
  State<MonitoringContent> createState() => _MonitoringContentState();
}

class _MonitoringContentState extends State<MonitoringContent> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Remaining-time column ticks every second from expiresAt
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المراقبة المباشرة'),
          actions: [
            BlocBuilder<MonitoringCubit, MonitoringState>(
              builder: (context, state) => _ConnectionChip(
                status: state is MonitoringReady
                    ? state.connection
                    : MonitoringConnectionStatus.connecting,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => context.read<MonitoringCubit>().refresh(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<MonitoringCubit, MonitoringState>(
          builder: (context, state) => switch (state) {
            MonitoringLoading() => const Center(child: CircularProgressIndicator()),
            MonitoringError(:final message) => _ErrorView(message: message),
            MonitoringReady(:final sessions) when sessions.isEmpty => const _EmptyView(),
            MonitoringReady(:final sessions) => _SessionsTable(sessions: sessions, now: _now),
          },
        ),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({required this.status});

  final MonitoringConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      MonitoringConnectionStatus.connected => (Colors.green, 'متصل', Icons.wifi),
      MonitoringConnectionStatus.connecting => (Colors.orange, 'جارٍ الاتصال...', Icons.wifi_find),
      MonitoringConnectionStatus.disconnected => (Colors.red, 'غير متصل', Icons.wifi_off),
    };
    return Center(
      child: Chip(
        avatar: Icon(icon, size: 16, color: color.shade700),
        label: Text(label, style: TextStyle(fontSize: 12, color: color.shade700)),
        backgroundColor: color.shade50,
        side: BorderSide(color: color.shade200),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: () => context.read<MonitoringCubit>().refresh(),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.podcasts, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'لا يوجد طلاب يؤدون امتحانات حالياً',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'ستظهر الجلسات هنا فور بدء أي طالب',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({required this.sessions, required this.now});

  final List<LiveSession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'الطلاب النشطون: ${sessions.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('الطالب')),
                  DataColumn(label: Text('رقم الجلوس')),
                  DataColumn(label: Text('الامتحان')),
                  DataColumn(label: Text('بدأ في')),
                  DataColumn(label: Text('الأسئلة المجابة')),
                  DataColumn(label: Text('الوقت المتبقي')),
                  DataColumn(label: Text('الحالة')),
                ],
                rows: sessions.map((session) => _row(session)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(LiveSession session) {
    final remaining = session.remainingAt(now);
    final lowTime = remaining.inMinutes < 5;
    return DataRow(
      cells: [
        DataCell(Text(session.studentName)),
        DataCell(Text(session.seatNumber)),
        DataCell(Text(session.examName)),
        DataCell(Text(DateFormat('HH:mm:ss').format(session.startedAt.toLocal()))),
        DataCell(Text('${session.answeredCount}')),
        DataCell(
          Text(
            _formatDuration(remaining),
            style: TextStyle(
              color: lowTime ? Colors.red.shade700 : null,
              fontWeight: lowTime ? FontWeight.bold : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        DataCell(_StatusBadge(status: session.status)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(duration.inHours)}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'IN_PROGRESS' => (Colors.green, 'يجيب الآن'),
      'SUBMITTED' => (Colors.blue, 'سلّم'),
      'EXPIRED' => (Colors.orange, 'انتهى الوقت'),
      'FORCE_ENDED' => (Colors.red, 'أُنهي إجبارياً'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color.shade700)),
    );
  }
}
