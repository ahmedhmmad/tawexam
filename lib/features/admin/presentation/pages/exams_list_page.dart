// lib/features/admin/presentation/pages/exams_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
        title: const Text('إدارة الامتحانات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'إنشاء امتحان',
            onPressed: () => _showExamDialog(context),
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
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (ctx, state) => switch (state) {
          ExamManagerLoading() => const Center(child: CircularProgressIndicator()),
          ExamManagerLoaded(:final exams) => () {
            final filtered = _search.isEmpty ? exams : exams.where((e) =>
              e.subjectNameAr.toLowerCase().contains(_search) ||
              e.subjectNameEn.toLowerCase().contains(_search) ||
              e.status.toLowerCase().contains(_search) ||
              _statusArabic(e.status).contains(_search)
            ).toList();
            return filtered.isEmpty
                ? const Center(child: Text('لا توجد امتحانات.'))
                : _ExamsList(exams: filtered, onEdit: (exam) => _showExamDialog(context, exam: exam));
          }(),
          ExamManagerError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('خطأ: $message'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => ctx.read<ExamManagerCubit>().load(), child: const Text('إعادة المحاولة')),
                ],
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  void _showExamDialog(BuildContext context, {AdminExam? exam}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ExamManagerCubit>(),
        child: _ExamFormDialog(exam: exam),
      ),
    );
  }
}

String _statusArabic(String status) => switch (status) {
  'DRAFT' => 'مسودة',
  'SCHEDULED' => 'مجدول',
  'ACTIVE' => 'نشط',
  'COMPLETED' => 'مكتمل',
  'ARCHIVED' => 'مؤرشف',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'DRAFT' => Colors.grey,
  'SCHEDULED' => Colors.blue,
  'ACTIVE' => Colors.green,
  'COMPLETED' => Colors.orange,
  'ARCHIVED' => Colors.brown,
  _ => Colors.grey,
};

class _ExamsList extends StatelessWidget {
  const _ExamsList({required this.exams, required this.onEdit});
  final List<AdminExam> exams;
  final void Function(AdminExam) onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: exams.length,
      itemBuilder: (ctx, i) => _ExamCard(exam: exams[i], onEdit: onEdit),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onEdit});
  final AdminExam exam;
  final void Function(AdminExam) onEdit;

  @override
  Widget build(BuildContext context) {
    final gazaStart = exam.startAt.toLocal();
    final gazaEnd = exam.endAt.toLocal();
    final dateFmt = DateFormat('yyyy/MM/dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.subjectNameAr.isNotEmpty ? exam.subjectNameAr : exam.subjectNameEn,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(exam.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusArabic(exam.status),
                    style: TextStyle(color: _statusColor(exam.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16, runSpacing: 4,
              children: [
                _InfoChip(Icons.timer, '${exam.durationMinutes} دقيقة'),
                _InfoChip(Icons.quiz, '${exam.totalQuestions} سؤال'),
                _InfoChip(Icons.people, '${exam.totalSessions} جلسة'),
                _InfoChip(Icons.repeat, '${exam.maxAttempts} محاولة'),
              ],
            ),
            const SizedBox(height: 8),
            Text('من: ${dateFmt.format(gazaStart)}  إلى: ${dateFmt.format(gazaEnd)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (exam.allowedBranches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  children: exam.allowedBranches.map((b) => Chip(
                    label: Text(b, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ActionBtn(Icons.edit, 'تعديل', () => onEdit(exam)),
                _ActionBtn(Icons.upload_file, 'أسئلة', () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => QuestionUploadPage(examId: exam.id)),
                )),
                _ActionBtn(Icons.list_alt, 'عرض', () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => QuestionsPage(
                    examId: exam.id,
                    examName: exam.subjectNameAr.isNotEmpty ? exam.subjectNameAr : exam.subjectNameEn,
                  )),
                )),
                _ActionBtn(Icons.swap_horiz, 'حالة', () => _showStatusDialog(context)),
                _ActionBtn(Icons.delete_outline, 'حذف', () => _confirmDelete(context), color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    final statuses = ['DRAFT', 'SCHEDULED', 'ACTIVE', 'COMPLETED', 'ARCHIVED'];
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('تغيير حالة الامتحان'),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            context.read<ExamManagerCubit>().updateStatus(exam.id, s);
          },
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('${_statusArabic(s)} ($s)'),
              if (exam.status == s) const Text(' ← الحالي', style: TextStyle(color: Colors.grey)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الامتحان؟'),
        content: const Text('يمكن حذف امتحانات المسودة فقط. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () { Navigator.pop(context); context.read<ExamManagerCubit>().delete(exam.id); },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(this.icon, this.label, this.onTap, {this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color ?? Colors.grey.shade700)),
          ]),
        ),
      ),
    );
  }
}

// ─── Exam Form Dialog (Create / Edit) ────────────────────────────────

class _ExamFormDialog extends StatefulWidget {
  const _ExamFormDialog({this.exam});
  final AdminExam? exam;

  @override
  State<_ExamFormDialog> createState() => _ExamFormDialogState();
}

class _ExamFormDialogState extends State<_ExamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameAr;
  late final TextEditingController _nameEn;
  late final TextEditingController _duration;
  late final TextEditingController _passingScore;
  late final TextEditingController _maxAttempts;
  late final TextEditingController _instructions;

  final Set<String> _selectedBranches = {};
  static const _allBranches = ['علمي', 'أدبي', 'شرعي', 'صناعي'];

  late DateTime _startDate;
  late DateTime _endDate;

  bool _showResults = false;
  bool _showAnswers = false;
  bool _activateNow = false;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _nameAr = TextEditingController(text: e?.subjectNameAr ?? '');
    _nameEn = TextEditingController(text: e?.subjectNameEn ?? '');
    _duration = TextEditingController(text: '${e?.durationMinutes ?? 60}');
    _passingScore = TextEditingController(text: '${e?.passingScore ?? 50}');
    _maxAttempts = TextEditingController(text: '${e?.maxAttempts ?? 1}');
    _instructions = TextEditingController(text: e?.instructions ?? '');

    if (e != null) {
      _selectedBranches.addAll(e.allowedBranches);
      // Dates from API are in UTC, convert to local for the picker
      _startDate = e.startAt.toLocal();
      _endDate = e.endAt.toLocal();
      _showResults = e.showResults;
      _showAnswers = e.showAnswers;
    } else {
      _selectedBranches.add('علمي');
      _startDate = DateTime.now().add(const Duration(hours: 1));
      _endDate = DateTime.now().add(const Duration(hours: 2));
    }
  }

  @override
  void dispose() {
    _nameAr.dispose(); _nameEn.dispose(); _duration.dispose();
    _passingScore.dispose(); _maxAttempts.dispose(); _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل الامتحان' : 'إنشاء امتحان جديد'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: _nameAr, decoration: const InputDecoration(labelText: 'اسم المادة (عربي)'), validator: (v) => (v ?? '').isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _nameEn, decoration: const InputDecoration(labelText: 'اسم المادة (إنجليزي)'), validator: (v) => (v ?? '').isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 12),

                const Text('الفروع المسموحة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allBranches.map((b) => FilterChip(
                    label: Text(b),
                    selected: _selectedBranches.contains(b),
                    onSelected: (selected) => setState(() {
                      selected ? _selectedBranches.add(b) : _selectedBranches.remove(b);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                const Text('التوقيت:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(child: _DateTimeTile(label: 'بداية الامتحان', value: _startDate, onPick: (d) => setState(() => _startDate = d))),
                  const SizedBox(width: 8),
                  Expanded(child: _DateTimeTile(label: 'نهاية الامتحان', value: _endDate, onPick: (d) => setState(() => _endDate = d))),
                ]),
                const SizedBox(height: 8),

                Row(children: [
                  Expanded(child: TextFormField(controller: _duration, decoration: const InputDecoration(labelText: 'المدة (دقيقة)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _passingScore, decoration: const InputDecoration(labelText: 'درجة النجاح %'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _maxAttempts, decoration: const InputDecoration(labelText: 'المحاولات'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                TextFormField(controller: _instructions, decoration: const InputDecoration(labelText: 'تعليمات الامتحان (اختياري)'), maxLines: 2),
                const SizedBox(height: 12),

                SwitchListTile(title: const Text('إظهار النتيجة للطالب'), value: _showResults, onChanged: (v) => setState(() => _showResults = v), dense: true, contentPadding: EdgeInsets.zero),
                SwitchListTile(title: const Text('إظهار الإجابات الصحيحة'), value: _showAnswers, onChanged: (v) => setState(() => _showAnswers = v), dense: true, contentPadding: EdgeInsets.zero),
                if (!_isEditing)
                  SwitchListTile(title: const Text('تفعيل فوري (بدون جدولة)'), value: _activateNow, onChanged: (v) => setState(() => _activateNow = v), dense: true, contentPadding: EdgeInsets.zero),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: _submit, child: Text(_isEditing ? 'حفظ التعديلات' : 'إنشاء')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر فرع واحد على الأقل')));
      return;
    }

    final now = DateTime.now();
    // The date picker returns local time (device is in Gaza timezone)
    // Just use them directly — the repository calls .toUtc().toIso8601String()
    final startAt = _activateNow ? now.subtract(const Duration(minutes: 1)) : _startDate;
    final endAt = _activateNow ? now.add(Duration(minutes: int.tryParse(_duration.text) ?? 60)) : _endDate;

    final params = CreateExamParams(
      subjectNameAr: _nameAr.text,
      subjectNameEn: _nameEn.text,
      examDate: startAt,
      startAt: startAt,
      endAt: endAt,
      durationMinutes: int.tryParse(_duration.text) ?? 60,
      passingScore: int.tryParse(_passingScore.text) ?? 50,
      allowedBranches: _selectedBranches.toList(),
      maxAttempts: int.tryParse(_maxAttempts.text) ?? 1,
      instructions: _instructions.text,
      showResults: _showResults,
      showAnswers: _showAnswers,
      status: _activateNow ? 'ACTIVE' : null,
    );

    if (_isEditing) {
      context.read<ExamManagerCubit>().update(widget.exam!.id, params);
    } else {
      context.read<ExamManagerCubit>().create(params);
    }
    Navigator.pop(context);
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.label, required this.value, required this.onPick});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2024), lastDate: DateTime(2030));
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        child: Text('${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
