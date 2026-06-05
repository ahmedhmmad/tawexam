// lib/features/admin/presentation/pages/question_upload_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/question_upload_cubit.dart';
import '../cubit/question_upload_state.dart';
import '../../domain/entities/upload_result.dart';
import '../../domain/entities/question_row.dart';

class QuestionUploadPage extends StatelessWidget {
  const QuestionUploadPage({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Questions')),
      body: BlocBuilder<QuestionUploadCubit, QuestionUploadState>(
        builder: (ctx, state) => switch (state) {
          QuestionUploadIdle() => _IdleBody(examId: examId),
          QuestionUploadParsing() =>
            const Center(child: CircularProgressIndicator()),
          QuestionUploadValidated(:final valid, :final errors) =>
            _ValidatedBody(valid: valid, errors: errors, examId: examId),
          QuestionUploadConfirming() =>
            const Center(child: CircularProgressIndicator()),
          QuestionUploadSuccess(:final imported) =>
            _SuccessBody(imported: imported),
          QuestionUploadFailure(:final message) =>
            _FailureBody(message: message),
        },
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select an .xlsx file to upload questions.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Pick File'),
            onPressed: () => _pick(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    if (!context.mounted) return;

    context.read<QuestionUploadCubit>().startParsing();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    context.read<QuestionUploadCubit>().validated(
          examId: examId,
          filePath: path,
          valid: [],
          errors: [],
        );
  }
}

class _ValidatedBody extends StatelessWidget {
  const _ValidatedBody({
    required this.valid,
    required this.errors,
    required this.examId,
  });

  final List<QuestionRow> valid;
  final List<RowError> errors;
  final String examId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Chip(
                  label: Text('${valid.length} valid'),
                  backgroundColor: Colors.green.shade100),
              const SizedBox(width: 8),
              if (errors.isNotEmpty)
                Chip(
                    label: Text('${errors.length} errors'),
                    backgroundColor: Colors.red.shade100),
              const Spacer(),
              if (errors.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download error report'),
                  onPressed: () {},
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: valid.length + errors.length,
            itemBuilder: (_, i) {
              if (i < valid.length) {
                final row = valid[i];
                return ListTile(
                  tileColor: Colors.green.shade50,
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text(row.text),
                  subtitle:
                      Text('Order: ${row.order} | ${row.difficulty}'),
                );
              }
              final err = errors[i - valid.length];
              return ListTile(
                tileColor: Colors.red.shade50,
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text('Row ${err.rowNumber}'),
                subtitle: Text(err.errors.join(', ')),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              TextButton(
                onPressed:
                    context.read<QuestionUploadCubit>().reset,
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: valid.isEmpty
                    ? null
                    : context
                        .read<QuestionUploadCubit>()
                        .executeImport,
                child: const Text('Confirm Import'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.imported});

  final int imported;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('$imported questions imported successfully.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  context.read<QuestionUploadCubit>().reset,
              child: const Text('Upload Another'),
            ),
          ],
        ),
      );
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed:
                  context.read<QuestionUploadCubit>().reset,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
}
