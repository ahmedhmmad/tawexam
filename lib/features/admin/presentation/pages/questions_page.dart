// lib/features/admin/presentation/pages/questions_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/api_config.dart';
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
    final nextOrder = _questions.isEmpty
        ? 1
        : (_questions.map((q) => (q['orderIndex'] as int?) ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _QuestionFormDialog(
        dio: _dio,
        examId: widget.examId,
        question: question,
        nextOrderIndex: nextOrder,
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
                _Thumbnail(imageUrl: question['imageUrl'] as String?),
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
                final hasImage = (c['imageUrl'] as String?)?.isNotEmpty == true;
                return Chip(
                  avatar: hasImage ? const Icon(Icons.image, size: 16) : null,
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    if (resolved == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          resolved,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined, size: 24, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Upload-backed image field: picks a local image, uploads it to the backend
/// and reports the stored URL. Shows a preview with a remove button when set.
class _ImagePickerField extends StatefulWidget {
  const _ImagePickerField({
    required this.dio,
    required this.label,
    required this.imageUrl,
    required this.onChanged,
    this.previewHeight = 96,
  });

  final Dio dio;
  final String label;
  final String? imageUrl;
  final ValueChanged<String?> onChanged;
  final double previewHeight;

  @override
  State<_ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<_ImagePickerField> {
  bool _uploading = false;

  static const _maxBytes = 2 * 1024 * 1024;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    if (bytes.length > _maxBytes) {
      _showError('Image exceeds the 2MB size limit');
      return;
    }

    setState(() => _uploading = true);
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      final response = await widget.dio.post<Map<String, dynamic>>(
        '/admin/uploads/question-image',
        data: form,
      );
      final url = (response.data?['data'] as Map?)?['url'] as String?;
      if (url != null) widget.onChanged(url);
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(widget.imageUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (resolved != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              resolved,
              height: widget.previewHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                height: widget.previewHeight,
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            tooltip: 'Remove image',
            onPressed: () => widget.onChanged(null),
          ),
        ],
        TextButton.icon(
          onPressed: _uploading ? null : _pickAndUpload,
          icon: _uploading
              ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.image_outlined, size: 18),
          label: Text(resolved == null ? widget.label : 'Replace'),
        ),
      ],
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.dio, required this.examId, this.question, this.nextOrderIndex = 1});

  final Dio dio;
  final String examId;
  final Map<String, dynamic>? question;
  final int nextOrderIndex;

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
  String? _questionImageUrl;
  late final Map<String, String?> _choiceImageUrls;
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
    String? choiceImage(String label) {
      final match = choices.where((c) => c['label'] == label).toList();
      final url = match.isNotEmpty ? match.first['imageUrl'] as String? : null;
      return (url?.isEmpty ?? true) ? null : url;
    }

    _text = TextEditingController(text: q?['text'] as String? ?? '');
    _choiceA = TextEditingController(text: choiceText('A'));
    _choiceB = TextEditingController(text: choiceText('B'));
    _choiceC = TextEditingController(text: choiceText('C'));
    _choiceD = TextEditingController(text: choiceText('D'));
    _explanation = TextEditingController(text: q?['explanation'] as String? ?? '');
    _category = TextEditingController(text: q?['category'] as String? ?? '');
    _correctAnswer = correctLabel();
    final questionImage = q?['imageUrl'] as String?;
    _questionImageUrl = (questionImage?.isEmpty ?? true) ? null : questionImage;
    _choiceImageUrls = {for (final label in ['A', 'B', 'C', 'D']) label: choiceImage(label)};
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
                const SizedBox(height: 4),
                _ImagePickerField(
                  dio: widget.dio,
                  label: 'Add question image',
                  imageUrl: _questionImageUrl,
                  onChanged: (url) => setState(() => _questionImageUrl = url),
                ),
                const SizedBox(height: 12),
                _choiceField('A', _choiceA),
                const SizedBox(height: 8),
                _choiceField('B', _choiceB),
                const SizedBox(height: 8),
                _choiceField('C', _choiceC),
                const SizedBox(height: 8),
                _choiceField('D', _choiceD),
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

  Widget _choiceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Choice $label'),
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        ),
        _ImagePickerField(
          dio: widget.dio,
          label: 'Add image',
          imageUrl: _choiceImageUrls[label],
          previewHeight: 56,
          onChanged: (url) => setState(() => _choiceImageUrls[label] = url),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    Map<String, dynamic> choice(String label, TextEditingController controller) {
      return {
        'label': label,
        'text': controller.text,
        'imageUrl': _choiceImageUrls[label],
        'isCorrect': _correctAnswer == label,
      };
    }

    final body = {
      'text': _text.text,
      'imageUrl': _questionImageUrl,
      'difficulty': _difficulty,
      'category': _category.text,
      'orderIndex': (widget.question?['orderIndex'] as int?) ?? widget.nextOrderIndex,
      if (_explanation.text.isNotEmpty) 'explanation': _explanation.text,
      'choices': [
        choice('A', _choiceA),
        choice('B', _choiceB),
        choice('C', _choiceC),
        choice('D', _choiceD),
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
