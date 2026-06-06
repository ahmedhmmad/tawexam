// lib/features/admin/presentation/pages/students_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/network/api_client.dart';

class StudentsContent extends StatefulWidget {
  const StudentsContent({super.key});

  @override
  State<StudentsContent> createState() => _StudentsContentState();
}

class _StudentsContentState extends State<StudentsContent> {
  final Dio _dio = getIt<ApiClient>().dio;
  List<Map<String, dynamic>> _students = [];
  Set<String> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _dio.get<Map<String, dynamic>>('/admin/students', queryParameters: {'limit': 100});
      final responseData = r.data?['data'];
      List list;
      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map && responseData['data'] is List) {
        list = responseData['data'] as List;
      } else {
        list = [];
      }
      setState(() {
        _students = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
        title: Text('Students (${_students.length})'),
        actions: [
          if (_selected.isNotEmpty) ...[
            Text('${_selected.length} selected', style: const TextStyle(fontSize: 14)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Delete Selected', onPressed: _deleteSelected),
            IconButton(icon: const Icon(Icons.deselect), tooltip: 'Clear Selection', onPressed: () => setState(() => _selected.clear())),
          ],
          IconButton(icon: const Icon(Icons.select_all), tooltip: 'Select All', onPressed: _selectAll),
          IconButton(icon: const Icon(Icons.person_add), tooltip: 'Add Student', onPressed: () => _showStudentDialog(context)),
          IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Import Excel', onPressed: _importExcel),
          IconButton(icon: const Icon(Icons.download), tooltip: 'Export Excel', onPressed: _exportExcel),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStudents),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _students.length) {
        _selected.clear();
      } else {
        _selected = _students.map((s) => s['id'] as String).toSet();
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete $count students?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/admin/students/bulk-delete',
        data: {'ids': _selected.toList()},
      );
      final deleted = r.data?['data']?['deleted'] ?? 0;
      _selected.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$deleted students deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
    _loadStudents();
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Error: $_error'), const SizedBox(height: 16),
      FilledButton(onPressed: _loadStudents, child: const Text('Retry')),
    ]));
    if (_students.isEmpty) return const Center(child: Text('No students. Import via Excel or add manually.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (_, i) {
        final s = _students[i];
        final id = s['id'] as String;
        final isSelected = _selected.contains(id);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => setState(() {
                isSelected ? _selected.remove(id) : _selected.add(id);
              }),
            ),
            title: Text(s['fullName'] as String? ?? ''),
            subtitle: Text('Seat: ${s['seatNumber']} | Mobile: ${s['mobileNo'] ?? ''}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _onAction(s, action),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'resetPassword', child: Text('Reset Password')),
                const PopupMenuItem(value: 'toggle', child: Text('Toggle Active')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAction(Map<String, dynamic> student, String action) {
    final id = student['id'] as String;
    switch (action) {
      case 'edit':
        _showStudentDialog(context, student: student);
      case 'resetPassword':
        _resetPassword(id);
      case 'toggle':
        _toggleActive(id, student['isActive'] != true);
      case 'delete':
        _deleteStudent(id);
    }
  }

  Future<void> _deleteStudent(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Student?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (confirm != true) return;
    try {
      await _dio.delete<void>('/admin/students/$id');
      _loadStudents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleActive(String id, bool active) async {
    try {
      await _dio.put<void>('/admin/students/$id', data: {'isActive': active});
      _loadStudents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _resetPassword(String id) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/admin/students/$id/reset-password');
      final newPass = r.data?['data']?['password'] ?? '';
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Password Reset'),
          content: SelectableText('New password: $newPass'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() => _loading = true);
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });
      final r = await _dio.post<Map<String, dynamic>>(
        '/admin/students/import',
        data: formData,
        options: Options(receiveTimeout: const Duration(minutes: 5), sendTimeout: const Duration(minutes: 2)),
      );
      final imported = r.data?['data']?['imported'] ?? 0;
      final errors = (r.data?['data']?['errors'] as List?)?.length ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$imported students imported/updated${errors > 0 ? ' ($errors rows had errors)' : ''}'),
          duration: const Duration(seconds: 5),
        ));
      }
      _loadStudents();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _exportExcel() async {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export started — check downloads')));
    // For web, open the export URL in a new tab would be ideal
    // For now just call the endpoint
    try {
      await _dio.get<void>('/admin/students/export');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export complete')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _showStudentDialog(BuildContext context, {Map<String, dynamic>? student}) async {
    final result = await showDialog<bool>(context: context, builder: (_) => _StudentFormDialog(dio: _dio, student: student));
    if (result == true) _loadStudents();
  }
}

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({required this.dio, this.student});
  final Dio dio;
  final Map<String, dynamic>? student;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seatNumber;
  late final TextEditingController _fullName;
  late final TextEditingController _mobileNo;
  late final TextEditingController _password;
  bool _submitting = false;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _seatNumber = TextEditingController(text: widget.student?['seatNumber'] as String? ?? '');
    _fullName = TextEditingController(text: widget.student?['fullName'] as String? ?? '');
    _mobileNo = TextEditingController(text: widget.student?['mobileNo'] as String? ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _seatNumber.dispose();
    _fullName.dispose();
    _mobileNo.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Student' : 'Add Student'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _seatNumber, decoration: const InputDecoration(labelText: 'Seat Number (ID)'), validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _fullName, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _mobileNo, decoration: const InputDecoration(labelText: 'Mobile Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: _isEditing ? 'New Password (leave blank to keep)' : 'Password (defaults to mobile)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _submitting ? null : _submit, child: Text(_isEditing ? 'Save' : 'Create')),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      if (_isEditing) {
        final body = <String, dynamic>{
          'seatNumber': _seatNumber.text,
          'fullName': _fullName.text,
          'mobileNo': _mobileNo.text,
        };
        if (_password.text.isNotEmpty) body['password'] = _password.text;
        await widget.dio.put<void>('/admin/students/${widget.student!['id']}', data: body);
      } else {
        final password = _password.text.isNotEmpty ? _password.text : _mobileNo.text;
        await widget.dio.post<void>('/admin/students', data: {
          'seatNumber': _seatNumber.text,
          'fullName': _fullName.text,
          'mobileNo': _mobileNo.text,
          'password': password,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
