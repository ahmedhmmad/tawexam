// lib/features/admin/presentation/pages/results_page.dart
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.examId, required this.examName});
  final String examId;
  final String examName;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final Dio _dio = getIt<ApiClient>().dio;
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _dio.get<dynamic>('/admin/exams/${widget.examId}/results/list');
      final body = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      final data = body['data'];
      List list = data is List ? data : [];
      setState(() {
        _results = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _exportExcel() async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/exams/${widget.examId}/results/export',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes != null) {
        final blob = html.Blob([bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', 'results_${widget.examId}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري تحميل ملف النتائج...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التصدير: $e')),
        );
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final response = await _dio.get<List<int>>(
        '/admin/exams/${widget.examId}/questions/template',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes != null) {
        final blob = html.Blob([bytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', 'questions_template_${widget.examId}.xlsx')
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري تحميل قالب الأسئلة...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحميل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج: ${widget.examName}'),
        actions: [
          TextButton.icon(
            onPressed: _exportExcel,
            icon: const Icon(Icons.download),
            label: const Text('تصدير Excel'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _downloadTemplate,
            icon: const Icon(Icons.file_download),
            label: const Text('تحميل قالب الأسئلة'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadResults,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('خطأ: $_error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadResults,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج لهذا الامتحان.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('رقم الجلوس', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الفرع', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('العلامة', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('الصحيح/الكلي', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الوقت', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _results.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final timeSec = (r['timeTakenSeconds'] as int?) ?? 0;
            final timeMin = (timeSec / 60).floor();
            final timeSec2 = timeSec % 60;
            final timeStr = timeSec > 0 ? '${timeMin}د ${timeSec2}ث' : '-';
            final score = r['score'];
            final status = r['status'] as String? ?? '';
            final statusAr = switch(status) {
              'SUBMITTED' => 'مسلّم',
              'IN_PROGRESS' => 'جارٍ',
              'EXPIRED' => 'منتهي',
              'FORCE_ENDED' => 'أُنهي',
              _ => status,
            };
            final bgColor = i.isEven ? Colors.white : Colors.blue.shade50;
            return DataRow(
              color: WidgetStateProperty.all(bgColor),
              cells: [
              DataCell(Text(r['studentName'] as String? ?? '')),
              DataCell(Text(r['seatNumber'] as String? ?? '')),
              DataCell(Text(r['branch'] as String? ?? '')),
              DataCell(Text(statusAr)),
              DataCell(Text(score != null ? '$score%' : '-')),
              DataCell(Text('${r['correctCount'] ?? 0} / ${r['totalQuestions'] ?? 0}')),
              DataCell(Text(timeStr)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
