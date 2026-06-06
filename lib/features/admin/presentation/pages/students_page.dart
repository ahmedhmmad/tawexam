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
  bool _selectAll = false; // true = select ALL matching (not just page)
  bool _loading = true;
  String? _error;
  String _search = '';
  int _page = 1;
  int _total = 0;
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{'limit': _pageSize, 'page': _page};
      if (_search.isNotEmpty) params['search'] = _search;
      final r = await _dio.get<Map<String, dynamic>>('/admin/students', queryParameters: params);
      final responseData = r.data?['data'];
      List list;
      int total = 0;
      if (responseData is Map && responseData['data'] is List) {
        list = responseData['data'] as List;
        total = (responseData['total'] as int?) ?? list.length;
      } else if (responseData is List) {
        list = responseData;
        total = list.length;
      } else {
        list = [];
      }
      setState(() {
        _students = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _total = total;
        _loading = false;
        _selected.clear();
        _selectAll = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _pageSize).ceil();
    return Scaffold(
      appBar: AppBar(
        title: Text('الطلاب ($_total)'),
        actions: [
          if (_selected.isNotEmpty || _selectAll) ...[
            Text(_selectAll ? 'الكل ($_total)' : '${_selected.length} محدد'),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'حذف المحدد', onPressed: _deleteSelected),
            IconButton(icon: const Icon(Icons.deselect), tooltip: 'إلغاء التحديد', onPressed: () => setState(() { _selected.clear(); _selectAll = false; })),
          ],
          IconButton(icon: const Icon(Icons.person_add), tooltip: 'إضافة طالب', onPressed: () => _showStudentDialog(context)),
          IconButton(icon: const Icon(Icons.upload_file), tooltip: 'استيراد Excel', onPressed: _importExcel),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStudents),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو رقم الجلوس أو الموبايل...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onSubmitted: (v) { _search = v; _page = 1; _loadStudents(); },
              onChanged: (v) {
                if (v.isEmpty && _search.isNotEmpty) { _search = ''; _page = 1; _loadStudents(); }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Select controls
          if (_students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _selected.length == _students.length && _students.isNotEmpty,
                    onChanged: (_) => _togglePageSelect(),
                  ),
                  TextButton(onPressed: _togglePageSelect, child: const Text('تحديد الصفحة')),
                  if (_total > _pageSize) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => setState(() { _selectAll = !_selectAll; if (!_selectAll) _selected.clear(); }),
                      child: Text(_selectAll ? 'إلغاء تحديد الكل' : 'تحديد الكل ($_total)'),
                    ),
                  ],
                ],
              ),
            ),
          // List
          Expanded(child: _buildBody()),
          // Pagination
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: _page > 1 ? () { _page--; _loadStudents(); } : null),
                  Text('$_page / $totalPages'),
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: _page < totalPages ? () { _page++; _loadStudents(); } : null),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _togglePageSelect() {
    setState(() {
      if (_selected.length == _students.length) {
        _selected.clear();
        _selectAll = false;
      } else {
        _selected = _students.map((s) => s['id'] as String).toSet();
      }
    });
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('خطأ: $_error'), const SizedBox(height: 16),
      FilledButton(onPressed: _loadStudents, child: const Text('إعادة المحاولة')),
    ]));
    if (_students.isEmpty) return const Center(child: Text('لا يوجد طلاب.'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      itemBuilder: (_, i) {
        final s = _students[i];
        final id = s['id'] as String;
        final isSelected = _selectAll || _selected.contains(id);
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: ListTile(
            dense: true,
            leading: Checkbox(
              value: isSelected,
              onChanged: (_) => setState(() {
                isSelected ? _selected.remove(id) : _selected.add(id);
                if (_selected.isEmpty) _selectAll = false;
              }),
            ),
            title: Text(s['fullName'] as String? ?? ''),
            subtitle: Text('${s['seatNumber']} | ${s['mobileNo'] ?? ''}'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _onAction(s, action),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                const PopupMenuItem(value: 'resetPassword', child: Text('إعادة تعيين كلمة المرور')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
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
      case 'edit': _showStudentDialog(context, student: student);
      case 'resetPassword': _resetPassword(id);
      case 'delete': _deleteStudent(id);
    }
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await _dio.delete<void>('/admin/students/$id');
      _loadStudents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteSelected() async {
    final count = _selectAll ? _total : _selected.length;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('حذف $count طالب؟'),
      content: const Text('لا يمكن التراجع عن هذا الإجراء.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
      ],
    ));
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      if (_selectAll) {
        // Delete all matching the current search
        await _dio.post<Map<String, dynamic>>(
          '/admin/students/bulk-delete',
          data: {'ids': 'all', if (_search.isNotEmpty) 'search': _search},
        );
      } else {
        await _dio.post<Map<String, dynamic>>(
          '/admin/students/bulk-delete',
          data: {'ids': _selected.toList()},
        );
      }
      _selected.clear();
      _selectAll = false;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف $count طالب')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
    }
    _loadStudents();
  }

  Future<void> _resetPassword(String id) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/admin/students/$id/reset-password');
      final newPass = r.data?['data']?['password'] ?? '';
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('إعادة تعيين كلمة المرور'),
          content: SelectableText('كلمة المرور الجديدة: $newPass'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
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
      final formData = FormData.fromMap({'file': MultipartFile.fromBytes(file.bytes!, filename: file.name)});
      final r = await _dio.post<Map<String, dynamic>>(
        '/admin/students/import',
        data: formData,
        options: Options(receiveTimeout: const Duration(minutes: 5), sendTimeout: const Duration(minutes: 2)),
      );
      final imported = r.data?['data']?['imported'] ?? 0;
      final errors = (r.data?['data']?['errors'] as List?)?.length ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم استيراد/تحديث $imported طالب${errors > 0 ? ' ($errors أخطاء)' : ''}'),
          duration: const Duration(seconds: 5),
        ));
      }
      _loadStudents();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الاستيراد: $e')));
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
  late final TextEditingController _branch;
  late final TextEditingController _password;
  bool _submitting = false;

  bool get _isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _seatNumber = TextEditingController(text: widget.student?['seatNumber'] as String? ?? '');
    _fullName = TextEditingController(text: widget.student?['fullName'] as String? ?? '');
    _mobileNo = TextEditingController(text: widget.student?['mobileNo'] as String? ?? '');
    _branch = TextEditingController(text: widget.student?['branch'] as String? ?? '');
    _password = TextEditingController();
  }

  @override
  void dispose() { _seatNumber.dispose(); _fullName.dispose(); _mobileNo.dispose(); _branch.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل طالب' : 'إضافة طالب'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _seatNumber, decoration: const InputDecoration(labelText: 'رقم الجلوس'), validator: (v) => (v ?? '').isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 8),
            TextFormField(controller: _fullName, decoration: const InputDecoration(labelText: 'الاسم الكامل'), validator: (v) => (v ?? '').isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 8),
            TextFormField(controller: _mobileNo, decoration: const InputDecoration(labelText: 'رقم الموبايل'), keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            TextFormField(controller: _branch, decoration: const InputDecoration(labelText: 'الفرع', hintText: 'علمي، أدبي...')),
            const SizedBox(height: 8),
            TextFormField(controller: _password, decoration: InputDecoration(labelText: _isEditing ? 'كلمة مرور جديدة (اتركها فارغة للإبقاء)' : 'كلمة المرور (افتراضي = الموبايل)')),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: _submitting ? null : _submit, child: Text(_isEditing ? 'حفظ' : 'إنشاء')),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      if (_isEditing) {
        final body = <String, dynamic>{'seatNumber': _seatNumber.text, 'fullName': _fullName.text, 'mobileNo': _mobileNo.text, 'branch': _branch.text};
        if (_password.text.isNotEmpty) body['password'] = _password.text;
        await widget.dio.put<void>('/admin/students/${widget.student!['id']}', data: body);
      } else {
        await widget.dio.post<void>('/admin/students', data: {
          'seatNumber': _seatNumber.text, 'fullName': _fullName.text, 'mobileNo': _mobileNo.text,
          'branch': _branch.text,
          'password': _password.text.isNotEmpty ? _password.text : _mobileNo.text,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: $e')));
    }
  }
}
