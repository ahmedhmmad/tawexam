import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../cubit/exam_cubit.dart';
import 'instructions_page.dart';

/// Gaza timezone offset (UTC+3)
DateTime _toGaza(DateTime utc) => utc.toUtc().add(const Duration(hours: 3));

/// Branch color mapping
Color _branchColor(String branch) => switch (branch) {
  'علمي' => const Color(0xFF1565C0), // blue
  'أدبي' => const Color(0xFF2E7D32), // green
  'شرعي' => const Color(0xFF6A1B9A), // purple
  'صناعي' => const Color(0xFFE65100), // orange
  _ => const Color(0xFF546E7A),       // grey-blue default
};

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({required this.student, super.key});
  final Student student;

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final Dio _dio = getIt<ApiClient>().dio;
  Map<String, dynamic>? _currentExam;
  List<Map<String, dynamic>> _allExams = [];
  List<Map<String, dynamic>> _pastExams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load current exam(s)
      try {
        final r = await _dio.get<Map<String, dynamic>>('/exam/current');
        final data = r.data?['data'];
        if (data is List && data.isNotEmpty) {
          // Multiple exams returned — show all as cards
          _currentExam = data.first as Map<String, dynamic>?;
          _allExams = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is Map) {
          _currentExam = Map<String, dynamic>.from(data);
          _allExams = [_currentExam!];
        } else {
          _currentExam = null;
          _allExams = [];
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          _currentExam = null;
          _allExams = [];
        } else {
          _currentExam = null;
          _allExams = [];
          _error = 'exam: ${e.response?.statusCode} ${e.message}';
        }
      } catch (e) {
        _currentExam = null;
        _allExams = [];
        _error = 'exam-err: $e';
      }

      // Load past exams - optional
      try {
        final r = await _dio.get<Map<String, dynamic>>('/exam/history');
        final list = r.data?['data'] as List?;
        _pastExams = list?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      } catch (_) {
        _pastExams = [];
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'load: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchCol = _branchColor(widget.student.branch);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, branchCol),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadExams,
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color branchCol) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [branchCol, branchCol.withValues(alpha: 0.75)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرحباً', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text(widget.student.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeaderBadge(Icons.confirmation_number, widget.student.seatNumber),
                    const SizedBox(width: 10),
                    if (widget.student.branch.isNotEmpty)
                      _BranchBadge(widget.student.branch),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 16),
          OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'), onPressed: _loadExams),
        ])),
      ]);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_allExams.isNotEmpty)
          ..._allExams.map((exam) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildExamCard(context, exam),
          ))
        else
          _buildNoExamCard(),
        if (_pastExams.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('امتحانات سابقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          ..._pastExams.map(_buildPastExamTile),
        ],
      ],
    );
  }

  Widget _buildNoExamCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا يوجد امتحانات متاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('سيظهر الامتحان هنا عند جدولته أو تفعيله.\nتأكد من الجدول مع المشرف.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('تحديث'), onPressed: _loadExams),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam) {
    final name = exam['subjectNameAr'] ?? exam['subjectNameEn'] ?? '';
    final duration = exam['durationMinutes'] ?? 0;
    final questions = exam['totalQuestions'] ?? 0;
    final maxAttempts = exam['maxAttempts'] ?? 1;
    final currentAttempt = (exam['currentAttempt'] as int?) ?? 1;
    final status = exam['status'] as String? ?? 'ACTIVE';
    final isScheduled = status == 'SCHEDULED';
    final isActive = status == 'ACTIVE';
    // Can only start if ACTIVE
    final canStart = isActive;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isScheduled ? Colors.blue : Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isScheduled ? Icons.schedule : Icons.assignment,
                    color: isScheduled ? Colors.blue : Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isScheduled ? Colors.blue.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isScheduled ? 'مجدول' : 'متاح الآن',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: isScheduled ? Colors.blue.shade700 : Colors.green.shade700),
                        ),
                      ),
                      if (maxAttempts > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('المحاولة $currentAttempt من $maxAttempts',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _ExamInfoTile(icon: Icons.timer, label: 'المدة', value: '$duration دقيقة'),
            const SizedBox(height: 8),
            _ExamInfoTile(icon: Icons.quiz, label: 'الأسئلة', value: '$questions سؤال'),
            const SizedBox(height: 8),
            if (maxAttempts > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExamInfoTile(icon: Icons.repeat, label: 'المحاولات', value: '$maxAttempts'),
              ),
            // Status indicator for scheduled exams
            if (isScheduled) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'بانتظار التفعيل من المشرف',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canStart ? () => _startExamFlow(context) : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  canStart ? 'بدء الامتحان' : 'الامتحان لم يبدأ بعد',
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastExamTile(Map<String, dynamic> exam) {
    final name = exam['subjectNameAr'] ?? exam['subjectNameEn'] ?? '';
    final score = exam['score'];
    final submittedAt = exam['submittedAt'] != null ? DateTime.tryParse(exam['submittedAt'] as String) : null;
    final dateStr = submittedAt != null ? DateFormat('yyyy/MM/dd').format(_toGaza(submittedAt)) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: score != null && score >= 50 ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            score != null && score >= 50 ? Icons.check : Icons.close,
            color: score != null && score >= 50 ? Colors.green : Colors.red,
          ),
        ),
        title: Text(name),
        subtitle: Text(dateStr),
        trailing: score != null
            ? Text('$score%', style: TextStyle(
                fontWeight: FontWeight.bold,
                color: score >= 50 ? Colors.green : Colors.red,
              ))
            : const Text('بانتظار النتيجة', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  void _startExamFlow(BuildContext context) {
    final cubit = context.read<ExamCubit>();
    // Reload exam + questions fresh before navigating
    cubit.loadForStudent(student: widget.student);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const InstructionsPage(),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await getIt<TokenProvider>().clearTokens();
    final storage = getIt<LocalStorageService>();
    await storage.delete('auth_box', 'cached_student');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BlocProvider(
          create: (_) => getIt<AuthCubit>(),
          child: const LoginPage(),
        )),
        (_) => false,
      );
    }
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _BranchBadge extends StatelessWidget {
  const _BranchBadge(this.branch);
  final String branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.school, size: 13, color: _branchColor(branch)),
        const SizedBox(width: 4),
        Text(branch, style: TextStyle(color: _branchColor(branch), fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _ExamInfoTile extends StatelessWidget {
  const _ExamInfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
