// lib/features/admin/presentation/pages/admin_results_overview_page.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/admin_exam.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/exam_manager_state.dart';
import 'results_page.dart';

class AdminResultsOverviewPage extends StatefulWidget {
  const AdminResultsOverviewPage({super.key});

  @override
  State<AdminResultsOverviewPage> createState() => _AdminResultsOverviewPageState();
}

class _AdminResultsOverviewPageState extends State<AdminResultsOverviewPage> {
  final Dio _dio = getIt<ApiClient>().dio;
  String? _selectedBranch;
  String? _selectedMonth; // 'yyyy-MM'
  String _search = '';

  static const _branches = ['علمي', 'أدبي', 'شرعي', 'صناعي'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النتائج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ExamManagerCubit>().load(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: BlocBuilder<ExamManagerCubit, ExamManagerState>(
              builder: (ctx, state) {
                if (state is ExamManagerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ExamManagerError) {
                  return _ErrorView(onRetry: () => ctx.read<ExamManagerCubit>().load());
                }
                if (state is ExamManagerLoaded) {
                  final filtered = _filterExams(state.exams);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('لا توجد امتحانات تطابق التصفية.'));
                  }
                  return _buildExamsList(filtered);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث باسم الامتحان...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBranch,
              decoration: const InputDecoration(
                labelText: 'الفرع',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('الكل')),
                ..._branches.map((b) => DropdownMenuItem(value: b, child: Text(b))),
              ],
              onChanged: (v) => setState(() => _selectedBranch = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'الشهر',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('كل الأشهر')),
                ..._monthOptions().map((m) => DropdownMenuItem(value: m, child: Text(_monthLabel(m)))),
              ],
              onChanged: (v) => setState(() => _selectedMonth = v),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _monthOptions() {
    // Last 12 months
    final now = DateTime.now();
    return List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i);
      return DateFormat('yyyy-MM').format(d);
    });
  }

  String _monthLabel(String yyyyMM) {
    final parts = yyyyMM.split('-');
    return '${parts[1]}/${parts[0]}';
  }

  List<AdminExam> _filterExams(List<AdminExam> exams) {
    return exams.where((e) {
      if (_search.isNotEmpty) {
        final name = '${e.subjectNameAr} ${e.subjectNameEn}'.toLowerCase();
        if (!name.contains(_search)) return false;
      }
      if (_selectedBranch != null && !e.allowedBranches.contains(_selectedBranch)) {
        return false;
      }
      if (_selectedMonth != null) {
        final examMonth = DateFormat('yyyy-MM').format(e.examDate.toLocal());
        if (examMonth != _selectedMonth) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildExamsList(List<AdminExam> exams) {
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: exams.length,
      itemBuilder: (_, i) {
        final exam = exams[i];
        final bgColor = i.isEven ? Colors.white : Colors.blue.shade50;
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          color: bgColor,
          child: ListTile(
            title: Text(
              exam.subjectNameAr.isNotEmpty ? exam.subjectNameAr : exam.subjectNameEn,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${dateFmt.format(exam.startAt.toLocal())}  •  ${exam.totalSessions} جلسة  •  ${exam.allowedBranches.join(", ")}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  tooltip: 'تصدير Excel',
                  onPressed: () => _exportExam(exam.id),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: 'عرض النتائج',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ResultsPage(
                        examId: exam.id,
                        examName: exam.subjectNameAr.isNotEmpty
                            ? exam.subjectNameAr
                            : exam.subjectNameEn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportExam(String examId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/exams/$examId/results/export',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes != null) {
        final blob = html.Blob([bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'results_$examId.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم بدء التحميل')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التحميل')),
        );
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('حدث خطأ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('خطأ مؤقت', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
