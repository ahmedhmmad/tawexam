import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_provider.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/contact_support.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/exam_result_model.dart';
import '../cubit/exam_cubit.dart';
import 'instructions_page.dart';
import 'result_page.dart';

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
      // Load available exams for display
      try {
        final r = await _dio.get<dynamic>('/exam/available');
        final body = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
        final data = body['data'];
        if (data is List && data.isNotEmpty) {
          _allExams = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          _allExams = [];
        }
      } on DioException catch (e) {
        _allExams = [];
        if (e.response?.statusCode != 404) {
          _error = _shortError(e.response?.statusCode);
        }
      } catch (_) {
        _allExams = [];
        _error = 'خطأ مؤقت';
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
    } catch (_) {
      setState(() { _error = 'خطأ مؤقت'; _loading = false; });
    }
  }

  String _shortError(int? code) {
    if (code == null) return 'خطأ في الاتصال';
    return 'خطأ $code';
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
    final name = widget.student.fullName.trim();
    final initial = name.isNotEmpty ? name.characters.first : '؟';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [branchCol, branchCol.withValues(alpha: 0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      // Decorative translucent circles add depth without any image weight.
      child: Stack(
        children: [
          Positioned(
            top: -30,
            left: -20,
            child: _decorCircle(110, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -24,
            left: 60,
            child: _decorCircle(70, Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: branchCol,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.support_agent, color: Colors.white),
                      tooltip: 'تواصل مع الدعم',
                      onPressed: _openSupport,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'تسجيل الخروج',
                      onPressed: _logout,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  static Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  void _openSupport() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: ContactSupport(prompt: 'هل تحتاج مساعدة أو نسيت كلمة المرور؟'),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير 👋';
    if (hour < 18) return 'مساء الخير 👋';
    return 'مساءكم بالخير 👋';
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 16),
          OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'), onPressed: _loadExams),
        ])),
      ]);
    }

    // Cap width and center so the layout reads well on tablet/desktop/web.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
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
        const SizedBox(height: 28),
        const ContactSupport(),
        const SizedBox(height: 8),
      ],
        ),
      ),
    );
  }

  /// Opens a past exam's result. Shows the score (and per-question answers when
  /// the supervisor enabled "show answers"), or a notice if results aren't
  /// released yet.
  Future<void> _openPastResult(Map<String, dynamic> exam) async {
    final examId = '${exam['examId'] ?? exam['id'] ?? ''}';
    if (examId.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final r = await _dio.get<Map<String, dynamic>>('/exam/$examId/result');
      final data = Map<String, dynamic>.from(r.data?['data'] as Map? ?? {});
      final result = ExamResultModel.fromJson(data);
      if (!mounted) return;
      Navigator.of(context).pop(); // close the loader
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultPage(result: result, student: widget.student),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل النتيجة، حاول لاحقاً')),
      );
    }
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(icon: Icons.timer_outlined, text: '$duration دقيقة'),
                _InfoPill(icon: Icons.quiz_outlined, text: '$questions سؤال'),
                if (maxAttempts > 1)
                  _InfoPill(icon: Icons.repeat, text: 'محاولات: $maxAttempts'),
              ],
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
            const SizedBox(height: 18),
            _StartExamButton(
              enabled: canStart,
              color: _branchColor(widget.student.branch),
              label: canStart ? 'بدء الامتحان' : 'الامتحان لم يبدأ بعد',
              onPressed: canStart ? () => _startExamFlow(context, exam) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastExamTile(Map<String, dynamic> exam) {
    final name = exam['subjectNameAr'] ?? exam['subjectNameEn'] ?? '';
    final score = exam['score'];
    // resultVisible is false when the admin/teacher hasn't released results yet;
    // the backend already withholds the score in that case (score == null).
    final resultVisible = exam['resultVisible'] as bool? ?? (score != null);
    final hasScore = score != null;
    final passed = hasScore && score >= 50;
    final submittedAt = exam['submittedAt'] != null ? DateTime.tryParse(exam['submittedAt'] as String) : null;
    final dateStr = submittedAt != null ? DateFormat('yyyy/MM/dd').format(_toGaza(submittedAt)) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasScore
              ? (passed ? Colors.green.shade100 : Colors.red.shade100)
              : Colors.grey.shade200,
          child: Icon(
            hasScore ? (passed ? Icons.check : Icons.close) : Icons.hourglass_empty,
            color: hasScore ? (passed ? Colors.green : Colors.red) : Colors.grey.shade600,
          ),
        ),
        title: Text(name),
        subtitle: Text(dateStr),
        onTap: () => _openPastResult(exam),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            hasScore
                ? Text('$score%', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : Colors.red,
                  ))
                : Text(
                    resultVisible ? 'بانتظار النتيجة' : 'لم تُعتمد النتيجة بعد',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
            Icon(Icons.chevron_left, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _startExamFlow(BuildContext context, Map<String, dynamic> exam) {
    final cubit = context.read<ExamCubit>();
    // Load the exam the student actually tapped (not the backend's "first")
    cubit.loadForStudent(student: widget.student, exam: ExamModel.fromJson(exam));
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

/// Compact info chip for exam metadata (duration, question count, attempts).
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Full-width gradient call-to-action that draws the eye to start the exam.
class _StartExamButton extends StatelessWidget {
  const _StartExamButton({
    required this.enabled,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final Color color;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: enabled
                  ? LinearGradient(colors: [color, color.withValues(alpha: 0.78)])
                  : null,
              color: enabled ? null : Colors.grey.shade300,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(enabled ? Icons.play_arrow_rounded : Icons.lock_clock,
                      color: enabled ? Colors.white : Colors.grey.shade600, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
