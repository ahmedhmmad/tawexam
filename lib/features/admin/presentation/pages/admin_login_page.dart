// lib/features/admin/presentation/pages/admin_login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/admin_auth_cubit.dart';
import '../cubit/admin_auth_state.dart';
import 'admin_shell_page.dart';

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
          if (state is AdminAuthFailure) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is AdminAuthSuccess) {
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                        value: ctx.read<AdminAuthCubit>(),
                        child: const AdminShellPage(),
                      )),
            );
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
                    Text('Admin Login',
                        style: Theme.of(ctx).textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                          (v ?? '').isEmpty ? 'Required' : null,
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
                          : const Text('Login'),
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
