// lib/features/admin/presentation/pages/question_upload_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class QuestionUploadPage extends StatefulWidget {
  const QuestionUploadPage({required this.examId, super.key});

  final String examId;

  @override
  State<QuestionUploadPage> createState() => _QuestionUploadPageState();
}

class _QuestionUploadPageState extends State<QuestionUploadPage> {
  _UploadStatus _status = _UploadStatus.idle;
  String? _message;
  int _imported = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Questions')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_status) {
            _UploadStatus.idle => _buildIdle(),
            _UploadStatus.uploading => const CircularProgressIndicator(),
            _UploadStatus.success => _buildSuccess(),
            _UploadStatus.error => _buildError(),
          },
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.upload_file, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Select an .xlsx file to upload questions.'),
        const SizedBox(height: 8),
        const Text(
          'Columns: question_text, choice_a, choice_b, choice_c, choice_d, correct_answer, explanation, difficulty, category, question_order',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('Pick Excel File'),
          onPressed: _pickAndUpload,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Text('$_imported questions imported successfully.'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _status = _UploadStatus.idle),
          child: const Text('Upload Another'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Exams'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(_message ?? 'Upload failed'),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() => _status = _UploadStatus.idle),
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // Required for web — gives us bytes
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    if (file.bytes == null && file.path == null) {
      setState(() {
        _status = _UploadStatus.error;
        _message = 'Could not read file';
      });
      return;
    }

    setState(() => _status = _UploadStatus.uploading);

    try {
      final dio = getIt<ApiClient>().dio;
      final formData = FormData.fromMap({
        'file': file.bytes != null
            ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
            : await MultipartFile.fromFile(file.path!, filename: file.name),
        'mode': 'append',
      });

      final response = await dio.post<Map<String, dynamic>>(
        '/admin/exams/${widget.examId}/questions/import',
        data: formData,
      );

      final data = response.data?['data'] as Map?;
      setState(() {
        _status = _UploadStatus.success;
        _imported = (data?['imported'] as int?) ?? 0;
      });
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data as Map)['error']?['message']?.toString()
          : e.message;
      setState(() {
        _status = _UploadStatus.error;
        _message = msg ?? 'Upload failed';
      });
    } catch (e) {
      setState(() {
        _status = _UploadStatus.error;
        _message = e.toString();
      });
    }
  }
}

enum _UploadStatus { idle, uploading, success, error }
