// lib/features/admin/presentation/pages/admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/admin_auth_cubit.dart';
import '../cubit/admin_auth_state.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AdminAuthCubit, AdminAuthState>(
        listener: (ctx, state) {
          // On success the auth gate (main_admin) reactively swaps to the
          // shell — no manual navigation needed here.
          if (state is AdminAuthFailure) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (ctx, state) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFF1E40AF)),
                    const SizedBox(height: 12),
                    Text('لوحة تحكم توجيهي',
                        textAlign: TextAlign.center,
                        style: Theme.of(ctx).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed:
                          state is AdminAuthLoading ? null : _submit,
                      child: state is AdminAuthLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Text('دخول'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminAuthCubit>().login(
          username: _usernameCtrl.text,
          password: _passwordCtrl.text,
        );
  }
}
