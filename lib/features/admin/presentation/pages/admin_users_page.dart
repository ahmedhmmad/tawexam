// lib/features/admin/presentation/pages/admin_users_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/entities/admin_role.dart';
import '../../domain/entities/admin_user.dart';
import '../cubit/admin_users_cubit.dart';
import '../cubit/admin_users_state.dart';

class AdminUsersContent extends StatelessWidget {
  const AdminUsersContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المستخدمون'),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('مستخدم جديد'),
              onPressed: () => _openForm(context),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => context.read<AdminUsersCubit>().load(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<AdminUsersCubit, AdminUsersState>(
          builder: (context, state) => switch (state) {
            AdminUsersLoading() => const Center(child: CircularProgressIndicator()),
            AdminUsersError(:final message) => _ErrorView(message: message),
            AdminUsersLoaded(:final users) when users.isEmpty => const _EmptyView(),
            AdminUsersLoaded(:final users) => _UsersTable(users: users),
          },
        ),
      ),
    );
  }

  static Future<void> _openForm(BuildContext context, {AdminUser? user}) async {
    final cubit = context.read<AdminUsersCubit>();
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(value: cubit, child: _UserFormDialog(user: user)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: () => context.read<AdminUsersCubit>().load(),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('لا يوجد مستخدمون', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});
  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
          columns: const [
            DataColumn(label: Text('اسم المستخدم')),
            DataColumn(label: Text('الدور')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('أُنشئ في')),
            DataColumn(label: Text('إجراءات')),
          ],
          rows: users.map((user) {
            return DataRow(cells: [
              DataCell(Text(user.username, textDirection: TextDirection.ltr)),
              DataCell(_RoleBadge(role: user.role)),
              DataCell(_StatusBadge(active: user.isActive)),
              DataCell(Text(user.createdAt == null ? '-' : dateFormat.format(user.createdAt!.toLocal()))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'تعديل',
                    onPressed: () => AdminUsersContent._openForm(context, user: user),
                  ),
                  IconButton(
                    icon: Icon(user.isActive ? Icons.block : Icons.check_circle, size: 20),
                    tooltip: user.isActive ? 'تعطيل' : 'تفعيل',
                    onPressed: () => _toggleActive(context, user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.key, size: 20),
                    tooltip: 'إعادة تعيين كلمة المرور',
                    onPressed: () => _resetPassword(context, user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'حذف',
                    onPressed: () => _delete(context, user),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, AdminUser user) async {
    final error = await context.read<AdminUsersCubit>().update(user.id, isActive: !user.isActive);
    _showError(context, error);
  }

  Future<void> _resetPassword(BuildContext context, AdminUser user) async {
    final controller = TextEditingController();
    final cubit = context.read<AdminUsersCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('كلمة مرور جديدة لـ ${user.username}'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (confirmed != true || controller.text.length < 8) {
      if (confirmed == true) _showError(context, 'كلمة المرور قصيرة جداً');
      return;
    }
    final error = await cubit.resetPassword(user.id, controller.text);
    _showError(context, error ?? 'تم تحديث كلمة المرور');
  }

  Future<void> _delete(BuildContext context, AdminUser user) async {
    final cubit = context.read<AdminUsersCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المستخدم؟'),
          content: Text('سيتم حذف "${user.username}" نهائياً.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final error = await cubit.delete(user.id);
    _showError(context, error);
  }

  void _showError(BuildContext context, String? message) {
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      AdminRole.superAdmin => Colors.purple,
      AdminRole.admin => Colors.blue,
      AdminRole.supervisor => Colors.teal,
      AdminRole.teacher => Colors.orange,
      AdminRole.unknown => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Text(role.labelAr, style: TextStyle(fontSize: 12, color: color.shade700)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    return Text(
      active ? 'مُفعّل' : 'معطّل',
      style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});
  final AdminUser? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _username;
  final _password = TextEditingController();
  late AdminRole _role;
  bool _submitting = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    final role = widget.user?.role ?? AdminRole.teacher;
    _role = role == AdminRole.unknown ? AdminRole.teacher : role;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(_isEditing ? 'تعديل المستخدم' : 'مستخدم جديد'),
        content: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _username,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'اسم المستخدم'),
                  validator: (v) => (v ?? '').trim().length < 3 ? '3 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AdminRole>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: const [AdminRole.superAdmin, AdminRole.admin, AdminRole.supervisor, AdminRole.teacher]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.labelAr)))
                      .toList(),
                  onChanged: (r) => setState(() => _role = r ?? _role),
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'كلمة المرور (8 أحرف على الأقل)'),
                    validator: (v) => (v ?? '').length < 8 ? '8 أحرف على الأقل' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_isEditing ? 'حفظ' : 'إنشاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final cubit = context.read<AdminUsersCubit>();
    final String? error;
    if (_isEditing) {
      error = await cubit.update(widget.user!.id, username: _username.text.trim(), role: _role);
    } else {
      error = await cubit.create(
        username: _username.text.trim(),
        password: _password.text,
        role: _role,
      );
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
