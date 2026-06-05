// lib/features/admin/presentation/pages/students_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/admin_student.dart';
import '../cubit/student_manager_cubit.dart';
import '../cubit/student_manager_state.dart';

class StudentsContent extends StatelessWidget {
  const StudentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import Students (Excel)',
            onPressed: () => _import(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Students',
            onPressed: () => _export(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<StudentManagerCubit>().load(),
          ),
        ],
      ),
      body: BlocConsumer<StudentManagerCubit, StudentManagerState>(
        listener: (ctx, state) {
          if (state is StudentManagerError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (ctx, state) => switch (state) {
          StudentManagerLoading() =>
            const Center(child: CircularProgressIndicator()),
          StudentManagerLoaded(:final students) => students.isEmpty
              ? const Center(child: Text('No students. Import via Excel.'))
              : _StudentsList(students: students),
          StudentManagerError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $message'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ctx.read<StudentManagerCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;
    context.read<StudentManagerCubit>().importFromFile(result.files.single.path!);
  }

  Future<void> _export(BuildContext context) async {
    final path = await context.read<StudentManagerCubit>().export();
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to: $path')),
      );
    }
  }
}

class _StudentsList extends StatelessWidget {
  const _StudentsList({required this.students});
  final List<AdminStudent> students;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (_, i) => _StudentTile(student: students[i]),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});
  final AdminStudent student;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: student.isActive ? Colors.green : Colors.grey,
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(student.fullName),
        subtitle: Text(
          '${student.seatNumber} | ${student.branch} | ${student.schoolName}',
        ),
        trailing: Icon(
          student.isActive ? Icons.check_circle : Icons.cancel,
          color: student.isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
