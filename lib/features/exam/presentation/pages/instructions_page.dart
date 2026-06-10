import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/exam_cubit.dart';
import '../cubit/exam_state.dart';
import 'question_page.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الامتحانات')),
        body: BlocBuilder<ExamCubit, ExamState>(
          builder: (context, state) {
            return switch (state) {
              ExamLoading() => const Center(child: CircularProgressIndicator()),
              ExamReady ready => _InstructionsContent(ready: ready),
              ExamError(:final message) => _NoExamView(error: message),
              _ => const _NoExamView(),
            };
          },
        ),
      ),
    );
  }
}

class _NoExamView extends StatelessWidget {
  const _NoExamView({this.onRetry, this.error});
  final VoidCallback? onRetry;
  final String? error;

  String _shortenError(String err) {
    // Extract only short error code (e.g., "400", "404", "Connection failed")
    if (err.contains('400')) return 'خطأ 400';
    if (err.contains('401')) return 'خطأ 401';
    if (err.contains('404')) return 'خطأ 404';
    if (err.contains('500')) return 'خطأ 500';
    if (err.toLowerCase().contains('connection') || err.toLowerCase().contains('network')) {
      return 'خطأ في الاتصال';
    }
    if (err.toLowerCase().contains('host lookup')) return 'خطأ في الاتصال';
    if (err.toLowerCase().contains('timeout')) return 'انتهت المهلة';
    return 'خطأ مؤقت';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'لا يوجد امتحانات لعرضها',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                _shortenError(error!),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'لا يوجد امتحان متاح لك حالياً.\nسيظهر الامتحان هنا عند اقتراب موعده.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InstructionsContent extends StatelessWidget {
  const _InstructionsContent({required this.ready});

  final ExamReady ready;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Exam card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment, color: Color(0xFF1E40AF), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ready.exam.displayName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.timer, label: 'مدة الامتحان', value: '${ready.exam.duration.inMinutes} دقيقة'),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.quiz, label: 'عدد الأسئلة', value: '${ready.questions.length} سؤال'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Instructions
        if (ready.exam.instructions.isNotEmpty) ...[
          Text('تعليمات الامتحان:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...ready.exam.instructions.map(_RuleTile.new),
          const SizedBox(height: 24),
        ],

        // General rules
        Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text('ملاحظات مهمة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• لا يمكن إيقاف المؤقت بعد بدء الامتحان'),
                const Text('• يتم حفظ إجاباتك تلقائياً'),
                const Text('• يمكنك التنقل بين الأسئلة بحرية'),
                const Text('• سيتم تسليم الامتحان تلقائياً عند انتهاء الوقت'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Start button
        FilledButton.icon(
          onPressed: () => _startExam(context),
          icon: const Icon(Icons.play_arrow),
          label: const Text('بدء الامتحان', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Future<void> _startExam(BuildContext context) async {
    await context.read<ExamCubit>().startExam();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ExamCubit>(),
          child: const QuestionPage(),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
