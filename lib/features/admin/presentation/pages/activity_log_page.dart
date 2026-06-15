// lib/features/admin/presentation/pages/activity_log_page.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/activity_event.dart';
import '../../domain/entities/admin_exam.dart';
import '../cubit/activity_log_cubit.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/exam_manager_state.dart';

class ActivityLogContent extends StatefulWidget {
  const ActivityLogContent({super.key});

  @override
  State<ActivityLogContent> createState() => _ActivityLogContentState();
}

class _ActivityLogContentState extends State<ActivityLogContent> {
  final _studentCtrl = TextEditingController();
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    context.read<ActivityLogCubit>().load();
    // Lightweight "live" feed: refresh every 15s.
    _autoRefresh = Timer.periodic(const Duration(seconds: 15), (_) {
      context.read<ActivityLogCubit>().refresh();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _studentCtrl.dispose();
    super.dispose();
  }

  ActivityFilters get _filters => context.read<ActivityLogCubit>().filters;

  Future<void> _exportExcel() async {
    final f = _filters;
    try {
      final r = await getIt<ApiClient>().dio.get<List<int>>(
        '/admin/activity/export',
        queryParameters: {
          if (f.examId != null) 'examId': f.examId,
          if (f.studentId != null) 'studentId': f.studentId,
          if (f.eventType != null) 'eventType': f.eventType,
          if (f.from != null) 'from': f.from!.toIso8601String(),
          if (f.to != null) 'to': f.to!.toIso8601String(),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = r.data;
      if (bytes == null) return;
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'activity-log.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر التصدير، حاول لاحقاً')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سجل النشاط'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'تصدير Excel',
              onPressed: _exportExcel,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => context.read<ActivityLogCubit>().refresh(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _FiltersBar(studentCtrl: _studentCtrl),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ActivityLogCubit, ActivityLogState>(
                builder: (context, state) => switch (state) {
                  ActivityLogLoading() => const Center(child: CircularProgressIndicator()),
                  ActivityLogError(:final message) => _ErrorView(message: message),
                  ActivityLogLoaded(:final events) when events.isEmpty => const _EmptyView(),
                  ActivityLogLoaded(:final events, :final total) =>
                    _EventList(events: events, total: total),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.studentCtrl});
  final TextEditingController studentCtrl;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ActivityLogCubit>();
    final f = context.watch<ActivityLogCubit>().filters;
    final dateFmt = DateFormat('yyyy/MM/dd');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Exam filter
          BlocBuilder<ExamManagerCubit, ExamManagerState>(
            builder: (context, state) {
              final exams = state is ExamManagerLoaded ? state.exams : <AdminExam>[];
              return SizedBox(
                width: 240,
                child: DropdownButtonFormField<String?>(
                  value: f.examId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'الامتحان', isDense: true, border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('كل الامتحانات')),
                    ...exams.map((e) => DropdownMenuItem(value: e.id, child: Text(e.subjectNameAr, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) => cubit.load(f.copyWith(examId: v, clearExam: v == null)),
                ),
              );
            },
          ),
          // Event type filter
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              value: f.eventType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'نوع الحدث', isDense: true, border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الأحداث')),
                ...kActivityEventLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => cubit.load(f.copyWith(eventType: v, clearEvent: v == null)),
            ),
          ),
          // Student id filter
          SizedBox(
            width: 200,
            child: TextField(
              controller: studentCtrl,
              decoration: InputDecoration(
                labelText: 'معرّف الطالب',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  onPressed: () => cubit.load(f.copyWith(studentId: studentCtrl.text.trim())),
                ),
              ),
              onSubmitted: (v) => cubit.load(f.copyWith(studentId: v.trim())),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(f.from == null
                ? 'كل الفترات'
                : '${dateFmt.format(f.from!)} — ${dateFmt.format(f.to ?? f.from!)}'),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now,
                locale: const Locale('ar'),
              );
              if (picked != null) {
                cubit.load(f.copyWith(from: picked.start, to: picked.end.add(const Duration(days: 1))));
              }
            },
          ),
          if (f.examId != null || f.eventType != null || (f.studentId?.isNotEmpty ?? false) || f.from != null)
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('مسح الفلاتر'),
              onPressed: () {
                studentCtrl.clear();
                cubit.load(const ActivityFilters());
              },
            ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events, required this.total});
  final List<ActivityEvent> events;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('عدد الأحداث: $total', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _EventTile(event: events[i]),
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final label = kActivityEventLabels[event.eventType] ?? event.eventType;
    final (color, icon) = _styleFor(event.eventType);
    final time = DateFormat('yyyy/MM/dd HH:mm:ss').format(event.createdAt.toLocal());

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.shade50, child: Icon(icon, color: color.shade700, size: 20)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (event.studentId != null) 'طالب: ${event.studentId}',
          if (event.description != null) event.description!,
          time,
        ].join('  •  '), style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  (MaterialColor, IconData) _styleFor(String type) {
    switch (type) {
      case 'SUSPICIOUS_ACTIVITY':
      case 'EXAM_ABANDONED':
      case 'APP_BACKGROUNDED':
        return (Colors.red, Icons.warning_amber_rounded);
      case 'INTERNET_DISCONNECTED':
        return (Colors.orange, Icons.wifi_off);
      case 'INTERNET_RESTORED':
      case 'APP_FOREGROUNDED':
      case 'SYNC_COMPLETED':
        return (Colors.green, Icons.check_circle_outline);
      case 'EXAM_STARTED':
      case 'EXAM_OPENED':
      case 'SESSION_RESUMED':
        return (Colors.blue, Icons.play_circle_outline);
      case 'EXAM_SUBMITTED':
      case 'EXAM_AUTO_SUBMITTED':
        return (Colors.teal, Icons.assignment_turned_in);
      case 'ATTEMPT_EXHAUSTED':
        return (Colors.grey, Icons.lock_outline);
      default:
        return (Colors.indigo, Icons.event_note);
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text('لا توجد أحداث مطابقة', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
          onPressed: () => context.read<ActivityLogCubit>().load(),
        ),
      ]),
    );
  }
}
