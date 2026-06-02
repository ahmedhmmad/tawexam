import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taw_exam/core/errors/failures.dart';
import 'package:taw_exam/features/auth/domain/entities/auth_session.dart';
import 'package:taw_exam/features/auth/domain/repositories/auth_repository.dart';
import 'package:taw_exam/features/auth/domain/usecases/login_usecase.dart';
import 'package:taw_exam/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:taw_exam/features/auth/presentation/pages/login_page.dart';
import 'package:taw_exam/main.dart';

void main() {
  testWidgets('renders Arabic student login screen', (tester) async {
    await tester.pumpWidget(
      TawExamApp(
        homeOverride: BlocProvider(
          create: (_) => AuthCubit(LoginUseCase(_FakeAuthRepository())),
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('رقم الجلوس'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, AuthSession>> login({
    required String seatNumber,
    required String password,
  }) async {
    return const Left(AuthFailure('غير متصل بالخادم'));
  }
}
