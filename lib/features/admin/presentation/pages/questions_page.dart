// lib/features/admin/presentation/pages/questions_page.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({required this.examId, required this.examName, super.key});

  final String examId;
  final String examName;

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  final Dio _dio = getIt<ApiClient>().dio;
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/admin/exams/${widget.examId}/questions',
      );
      final list = (r.data?['data'] as List?) ?? [];
      setState(() {
        _questions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions — ${widget.examName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Question',
            onPressed: () => _showQuestionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuestions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $_error'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadQuestions, child: const Text('Retry')),
        ],
      ));
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions yet. Tap + to add one.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (_, i) => _QuestionCard(
        question: _questions[i],
        index: i,
        onEdit: () => _showQuestionDialog(context, question: _questions[i]),
        onDelete: () => _deleteQuestion(_questions[i]['id'] as String),
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _dio.delete<void>('/admin/questions/$id');
      _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _showQuestionDialog(BuildContext context, {Map<String, dynamic>? question}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _QuestionFormDialog(
        dio: _dio,
        examId: widget.examId,
        question: question,
      ),
    );
    if (result == true) _loadQuestions();
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final choices = (question['choices'] as List?) ?? [];
    final correctChoice = choices.where((c) => c['isCorrect'] == true).toList();
    final correctLabel = correctChoice.isNotEmpty ? correctChoice.first['label'] : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question['text'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: choices.map<Widget>((c) {
                final isCorrect = c['isCorrect'] == true;
                return Chip(
                  label: Text('${c['label']}: ${c['text']}'),
                  backgroundColor: isCorrect ? Colors.green.shade100 : null,
                  side: isCorrect ? const BorderSide(color: Colors.green) : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              'Correct: $correctLabel | ${question['difficulty']} | ${question['category']}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.dio, required this.examId, this.question});

  final Dio dio;
  final String examId;
  final Map<String, dynamic>? question;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final TextEditingController _choiceA;
  late final TextEditingController _choiceB;
  late final TextEditingController _choiceC;
  late final TextEditingController _choiceD;
  late final TextEditingController _explanation;
  late final TextEditingController _category;
  late String _correctAnswer;
  late String _difficulty;
  bool _submitting = false;

  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    final choices = (q?['choices'] as List?) ?? [];
    String choiceText(String label) {
      final match = choices.where((c) => c['label'] == label).toList();
      return match.isNotEmpty ? match.first['text'] as String : '';
    }
    String correctLabel() {
      final match = choices.where((c) => c['isCorrect'] == true).toList();
      return match.isNotEmpty ? match.first['label'] as String : 'A';
    }

    _text = TextEditingController(text: q?['text'] as String? ?? '');
    _choiceA = TextEditingController(text: choiceText('A'));
    _choiceB = TextEditingController(text: choiceText('B'));
    _choiceC = TextEditingController(text: choiceText('C'));
    _choiceD = TextEditingController(text: choiceText('D'));
    _explanation = TextEditingController(text: q?['explanation'] as String? ?? '');
    _category = TextEditingController(text: q?['category'] as String? ?? '');
    _correctAnswer = correctLabel();
    _difficulty = (q?['difficulty'] as String? ?? 'EASY').toUpperCase();
    if (!['EASY', 'MEDIUM', 'HARD'].contains(_difficulty)) _difficulty = 'EASY';
  }

  @override
  void dispose() {
    _text.dispose();
    _choiceA.dispose();
    _choiceB.dispose();
    _choiceC.dispose();
    _choiceD.dispose();
    _explanation.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Question' : 'Add Question'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _text,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                  maxLines: 3,
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _choiceA,
                  decoration: const InputDecoration(labelText: 'Choice A'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _choiceB,
                  decoration: const InputDecoration(labelText: 'Choice B'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _choiceC,
                  decoration: const InputDecoration(labelText: 'Choice C'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _choiceD,
                  decoration: const InputDecoration(labelText: 'Choice D'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _correctAnswer,
                  decoration: const InputDecoration(labelText: 'Correct Answer'),
                  items: ['A', 'B', 'C', 'D']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _correctAnswer = v ?? 'A'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: ['EASY', 'MEDIUM', 'HARD']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _difficulty = v ?? 'EASY'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _explanation,
                  decoration: const InputDecoration(labelText: 'Explanation (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final body = {
      'text': _text.text,
      'difficulty': _difficulty,
      'category': _category.text,
      'orderIndex': (widget.question?['orderIndex'] as int?) ?? 1,
      if (_explanation.text.isNotEmpty) 'explanation': _explanation.text,
      'choices': [
        {'label': 'A', 'text': _choiceA.text, 'isCorrect': _correctAnswer == 'A'},
        {'label': 'B', 'text': _choiceB.text, 'isCorrect': _correctAnswer == 'B'},
        {'label': 'C', 'text': _choiceC.text, 'isCorrect': _correctAnswer == 'C'},
        {'label': 'D', 'text': _choiceD.text, 'isCorrect': _correctAnswer == 'D'},
      ],
    };

    try {
      if (_isEditing) {
        await widget.dio.put<void>('/admin/questions/${widget.question!['id']}', data: body);
      } else {
        await widget.dio.post<void>('/admin/exams/${widget.examId}/questions', data: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
