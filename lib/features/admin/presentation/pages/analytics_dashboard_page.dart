// lib/features/admin/presentation/pages/analytics_dashboard_page.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/admin_exam.dart';
import '../../domain/entities/exam_result_summary.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/exam_manager_state.dart';
import '../cubit/results_cubit.dart';
import '../cubit/results_state.dart';

class AnalyticsDashboardContent extends StatefulWidget {
  const AnalyticsDashboardContent({super.key});

  @override
  State<AnalyticsDashboardContent> createState() => _AnalyticsDashboardContentState();
}

class _AnalyticsDashboardContentState extends State<AnalyticsDashboardContent> {
  String? _examId;
  String _examName = '';
  DateTimeRange? _dateRange;

  void _loadAnalytics() {
    final examId = _examId;
    if (examId == null) return;
    context.read<ResultsCubit>().load(
      examId,
      from: _dateRange?.start,
      // include the whole end day
      to: _dateRange?.end.add(const Duration(days: 1)),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _dateRange,
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadAnalytics();
    }
  }

  Future<void> _exportExcel() async {
    final examId = _examId;
    if (examId == null) return;
    try {
      final response = await getIt<ApiClient>().dio.get<List<int>>(
        '/admin/exams/$examId/results/export',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) return;
      final blob = html.Blob(
        [bytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', 'results_$examId.xlsx')
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تصدير الملف، حاول مجدداً')),
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
          title: const Text('لوحة الإحصائيات'),
          actions: [
            if (_examId != null)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'تصدير النتائج (Excel)',
                onPressed: _exportExcel,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _FiltersBar(
              examId: _examId,
              dateRange: _dateRange,
              onExamChanged: (exam) {
                setState(() {
                  _examId = exam.id;
                  _examName = exam.subjectNameAr;
                });
                _loadAnalytics();
              },
              onPickDateRange: _pickDateRange,
              onClearDateRange: _dateRange == null
                  ? null
                  : () {
                      setState(() => _dateRange = null);
                      _loadAnalytics();
                    },
            ),
            const Divider(height: 1),
            Expanded(
              child: _examId == null
                  ? const _SelectExamHint()
                  : BlocBuilder<ResultsCubit, ResultsState>(
                      builder: (context, state) => switch (state) {
                        ResultsInitial() || ResultsLoading() =>
                          const Center(child: CircularProgressIndicator()),
                        ResultsError(:final message) => _ErrorView(
                          message: message,
                          onRetry: _loadAnalytics,
                        ),
                        ResultsLoaded(:final summary) => _DashboardBody(
                          summary: summary,
                          examName: _examName,
                        ),
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
  const _FiltersBar({
    required this.examId,
    required this.dateRange,
    required this.onExamChanged,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  final String? examId;
  final DateTimeRange? dateRange;
  final ValueChanged<AdminExam> onExamChanged;
  final VoidCallback onPickDateRange;
  final VoidCallback? onClearDateRange;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          BlocBuilder<ExamManagerCubit, ExamManagerState>(
            builder: (context, state) {
              final exams = state is ExamManagerLoaded ? state.exams : <AdminExam>[];
              return SizedBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  value: examId,
                  decoration: const InputDecoration(
                    labelText: 'الامتحان',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: exams
                      .map((exam) => DropdownMenuItem(
                            value: exam.id,
                            child: Text(exam.subjectNameAr, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (id) {
                    final exam = exams.where((e) => e.id == id).firstOrNull;
                    if (exam != null) onExamChanged(exam);
                  },
                ),
              );
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              dateRange == null
                  ? 'كل الفترات'
                  : '${dateFormat.format(dateRange!.start)} — ${dateFormat.format(dateRange!.end)}',
            ),
            onPressed: onPickDateRange,
          ),
          if (onClearDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'إزالة فلتر التاريخ',
              onPressed: onClearDateRange,
            ),
        ],
      ),
    );
  }
}

class _SelectExamHint extends StatelessWidget {
  const _SelectExamHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'اختر امتحاناً لعرض إحصائياته',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.summary, required this.examName});

  final ExamResultSummary summary;
  final String examName;

  @override
  Widget build(BuildContext context) {
    if (summary.totalAttempts == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'لا توجد محاولات لهذا الامتحان في الفترة المحددة',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(examName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Responsive summary cards: wrap to fewer columns on narrow widths
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 36) / 4
                  : constraints.maxWidth >= 560
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    width: cardWidth,
                    icon: Icons.grade,
                    color: Colors.blue,
                    label: 'متوسط الدرجات',
                    value: '${summary.averageScore}%',
                  ),
                  _SummaryCard(
                    width: cardWidth,
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'نسبة النجاح',
                    value: '${summary.passRate}%',
                  ),
                  _SummaryCard(
                    width: cardWidth,
                    icon: Icons.task_alt,
                    color: Colors.orange,
                    label: 'نسبة الإكمال',
                    value: '${summary.completionRate}%',
                  ),
                  _SummaryCard(
                    width: cardWidth,
                    icon: Icons.people,
                    color: Colors.purple,
                    label: 'إجمالي المحاولات',
                    value: '${summary.totalAttempts}',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('توزيع الدرجات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: SizedBox(
                height: 320,
                child: _ScoreDistributionChart(scores: summary.distribution),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final MaterialColor color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.shade50,
                child: Icon(icon, color: color.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Histogram of scores bucketed by 10 (0–9, 10–19, …, 90–100).
class _ScoreDistributionChart extends StatelessWidget {
  const _ScoreDistributionChart({required this.scores});

  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    final buckets = List<int>.filled(10, 0);
    for (final score in scores) {
      final bucket = (score.clamp(0, 100) ~/ 10).clamp(0, 9);
      buckets[bucket]++;
    }
    final maxCount = buckets.fold(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 1).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${rod.toY.toInt()} طالب',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: maxCount <= 5 ? 1 : null,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final label = index == 9 ? '90+' : '${index * 10}';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxCount <= 5 ? 1 : null,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(10, (index) {
          final isPassBucket = index >= 5;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: buckets[index].toDouble(),
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                color: isPassBucket ? Colors.green.shade400 : Colors.red.shade300,
              ),
            ],
          );
        }),
      ),
    );
  }
}
