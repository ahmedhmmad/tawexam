// lib/features/admin/presentation/pages/exams_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_exam.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/exam_manager_cubit.dart';
import '../cubit/exam_manager_state.dart';
import 'question_upload_page.dart';
import 'questions_page.dart';

class ExamsListContent extends StatefulWidget {
  const ExamsListContent({super.key});

  @override
  State<ExamsListContent> createState() => _ExamsListContentState();
}

class _ExamsListContentState extends State<ExamsListContent> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الامتحانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إنشاء امتحان',
            onPressed: () => _showCreateDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => context.read<ExamManagerCubit>().load(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو الحالة...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: BlocConsumer<ExamManagerCubit, ExamManagerState>(
        listener: (ctx, state) {
          if (state is ExamManagerError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (ctx, state) => switch (state) {
          ExamManagerLoading() =>
            const Center(child: CircularProgressIndicator()),
          ExamManagerLoaded(:final exams) => () {
            final filtered = _search.isEmpty ? exams : exams.where((e) =>
              e.subjectNameAr.toLowerCase().contains(_search) ||
              e.subjectNameEn.toLowerCase().contains(_search) ||
              e.status.toLowerCase().contains(_search)
            ).toList();
            return filtered.isEmpty
                ? const Center(child: Text('لا توجد امتحانات.'))
                : _ExamsList(exams: filtered);
          }(),
          ExamManagerError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('خطأ: $message'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ctx.read<ExamManagerCubit>().load(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExamManagerCubit>(),
        child: const _CreateExamDialog(),
      ),
    );
  }
}

class _ExamsList extends StatelessWidget {
  const _ExamsList({required this.exams});
  final List<AdminExam> exams;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (ctx, i) => _ExamCard(exam: exams[i]),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final AdminExam exam;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(exam.subjectNameAr.isNotEmpty
            ? exam.subjectNameAr
            : exam.subjectNameEn),
        subtitle: Text(
          'Status: ${exam.status} | Duration: ${exam.durationMinutes}min | Questions: ${exam.totalQuestions}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _onAction(context, action),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'questions', child: Text('View Questions')),
            const PopupMenuItem(value: 'upload', child: Text('Upload Questions')),
            const PopupMenuItem(value: 'status', child: Text('Change Status')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  void _onAction(BuildContext context, String action) {
    final cubit = context.read<ExamManagerCubit>();
    if (action == 'questions') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionsPage(
            examId: exam.id,
            examName: exam.subjectNameAr.isNotEmpty ? exam.subjectNameAr : exam.subjectNameEn,
          ),
        ),
      );
    } else if (action == 'upload') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionUploadPage(examId: exam.id),
        ),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Exam?'),
          content: const Text('Only DRAFT exams can be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                cubit.delete(exam.id);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else if (action == 'status') {
      _showStatusDialog(context);
    }
  }

  void _showStatusDialog(BuildContext context) {
    final statuses = ['DRAFT', 'SCHEDULED', 'ACTIVE', 'COMPLETED', 'ARCHIVED'];
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Change Status'),
        children: statuses
            .map((s) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<ExamManagerCubit>().updateStatus(exam.id, s);
                  },
                  child: Text(s),
                ))
            .toList(),
      ),
    );
  }
}

class _CreateExamDialog extends StatefulWidget {
  const _CreateExamDialog();

  @override
  State<_CreateExamDialog> createState() => _CreateExamDialogState();
}

class _CreateExamDialogState extends State<_CreateExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameAr = TextEditingController();
  final _nameEn = TextEditingController();
  final _duration = TextEditingController(text: '60');
  final _passingScore = TextEditingController(text: '50');
  final _maxAttempts = TextEditingController(text: '1');
  final _instructions = TextEditingController();
  final _branches = TextEditingController(text: 'علمي');

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _duration.dispose();
    _passingScore.dispose();
    _maxAttempts.dispose();
    _instructions.dispose();
    _branches.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Exam'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameAr,
                  decoration: const InputDecoration(labelText: 'Subject (Arabic)'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameEn,
                  decoration: const InputDecoration(labelText: 'Subject (English)'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _duration,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passingScore,
                  decoration: const InputDecoration(labelText: 'Passing Score (%)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _maxAttempts,
                  decoration: const InputDecoration(labelText: 'Max Attempts'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _branches,
                  decoration: const InputDecoration(
                    labelText: 'Branches (comma separated)',
                    hintText: 'علمي, أدبي',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructions,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                  maxLines: 3,
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final start = now.add(const Duration(hours: 1));
    final end = start.add(Duration(minutes: int.tryParse(_duration.text) ?? 60));

    context.read<ExamManagerCubit>().create(CreateExamParams(
      subjectNameAr: _nameAr.text,
      subjectNameEn: _nameEn.text,
      examDate: now,
      startAt: start,
      endAt: end,
      durationMinutes: int.tryParse(_duration.text) ?? 60,
      passingScore: int.tryParse(_passingScore.text) ?? 50,
      allowedBranches:
          _branches.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      maxAttempts: int.tryParse(_maxAttempts.text) ?? 1,
      instructions: _instructions.text,
    ));
    Navigator.pop(context);
  }
}
