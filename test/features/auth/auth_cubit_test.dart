// test/features/auth/auth_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taw_exam/core/errors/failures.dart';
import 'package:taw_exam/features/auth/domain/entities/auth_session.dart';
import 'package:taw_exam/features/auth/domain/entities/student.dart';
import 'package:taw_exam/features/auth/domain/usecases/login_usecase.dart';
import 'package:taw_exam/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:taw_exam/features/auth/presentation/cubit/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late MockLoginUseCase loginUseCase;

  const student = Student(
    id: '1',
    seatNumber: 'S001',
    fullName: 'Test',
    branch: 'A',
    schoolName: 'School',
  );

  setUpAll(() => registerFallbackValue(
      const LoginParams(seatNumber: '', password: '')));
  setUp(() => loginUseCase = MockLoginUseCase());

  test('initial state is AuthInitial', () {
    expect(AuthCubit(loginUseCase).state, isA<AuthInitial>());
  });

  blocTest<AuthCubit, AuthState>(
    'emits [AuthLoading, AuthSuccess] on successful login',
    build: () {
      when(() => loginUseCase(any())).thenAnswer(
          (_) async => const Right(AuthSession(student: student)));
      return AuthCubit(loginUseCase);
    },
    act: (cubit) => cubit.login(seatNumber: 'S001', password: 'pass'),
    expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
  );

  blocTest<AuthCubit, AuthState>(
    'emits [AuthLoading, AuthFailure] on failed login',
    build: () {
      when(() => loginUseCase(any()))
          .thenAnswer((_) async => const Left(AuthFailure('error')));
      return AuthCubit(loginUseCase);
    },
    act: (cubit) => cubit.login(seatNumber: 'S001', password: 'pass'),
    expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
  );
}
