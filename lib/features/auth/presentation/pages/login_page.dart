import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exam/presentation/cubit/exam_cubit.dart';
import '../../../exam/presentation/pages/instructions_page.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _seatNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _seatNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: _listenToAuthState,
            builder: (context, state) => _buildForm(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: _LoginFields(
              state: state,
              seatNumberController: _seatNumberController,
              passwordController: _passwordController,
              isPasswordVisible: _isPasswordVisible,
              onTogglePassword: _togglePasswordVisibility,
              onSubmit: _submitLogin,
            ),
          ),
        ),
      ),
    );
  }

  void _listenToAuthState(BuildContext context, AuthState state) {
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (state is AuthSuccess) {
      _openInstructions(context, state);
    }
  }

  void _openInstructions(BuildContext context, AuthSuccess state) {
    final examCubit = getIt<ExamCubit>();
    examCubit.loadForStudent(student: state.student, session: state.session);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: examCubit,
          child: const InstructionsPage(),
        ),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      seatNumber: _seatNumberController.text,
      password: _passwordController.text,
    );
  }
}

class _LoginFields extends StatelessWidget {
  const _LoginFields({
    required this.state,
    required this.seatNumberController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final AuthState state;
  final TextEditingController seatNumberController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isLoading = state is AuthLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _LoginHeader(),
        const SizedBox(height: 32),
        _SeatNumberField(controller: seatNumberController),
        const SizedBox(height: 16),
        _PasswordField(
          controller: passwordController,
          isVisible: isPasswordVisible,
          onToggle: onTogglePassword,
        ),
        const SizedBox(height: 8),
        const _ForgotPasswordLink(),
        const SizedBox(height: 24),
        _LoginButton(isLoading: isLoading, onPressed: onSubmit),
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('تسجيل الدخول', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'أدخل رقم الجلوس وكلمة المرور للبدء.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _SeatNumberField extends StatelessWidget {
  const _SeatNumberField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'رقم الجلوس',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      textInputAction: TextInputAction.next,
      validator: _validateSeatNumber,
    );
  }

  static String? _validateSeatNumber(String? value) {
    final seatNumber = value?.trim() ?? '';
    if (seatNumber.isEmpty) return 'رقم الجلوس مطلوب';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(seatNumber)) {
      return 'رقم الجلوس يجب أن يحتوي على أحرف أو أرقام فقط';
    }
    return null;
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.isVisible,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          tooltip: isVisible ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
        ),
      ),
      textInputAction: TextInputAction.done,
      validator: _validatePassword,
    );
  }

  static String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'كلمة المرور مطلوبة';
    return null;
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: const Text('نسيت كلمة المرور؟'),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: isLoading ? const _ButtonLoader() : const Text('دخول'),
      ),
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
