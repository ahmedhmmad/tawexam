// test/features/auth/login_usecase_test.dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taw_exam/core/errors/failures.dart';
import 'package:taw_exam/features/auth/domain/entities/auth_session.dart';
import 'package:taw_exam/features/auth/domain/entities/student.dart';
import 'package:taw_exam/features/auth/domain/repositories/auth_repository.dart';
import 'package:taw_exam/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late LoginUseCase useCase;

  const student = Student(
    id: '1',
    seatNumber: 'S001',
    fullName: 'Test',
    branch: 'A',
    schoolName: 'School',
  );
  const session = AuthSession(student: student);

  setUp(() {
    repo = MockAuthRepository();
    useCase = LoginUseCase(repo);
  });

  test('returns AuthSession on success', () async {
    when(() => repo.login(seatNumber: 'S001', password: 'pass'))
        .thenAnswer((_) async => const Right(session));

    final result = await useCase(
        const LoginParams(seatNumber: 'S001', password: 'pass'));

    expect(result, const Right<Failure, AuthSession>(session));
    verify(() => repo.login(seatNumber: 'S001', password: 'pass'))
        .called(1);
  });

  test('returns AuthFailure on failure', () async {
    when(() => repo.login(
            seatNumber: any(named: 'seatNumber'),
            password: any(named: 'password')))
        .thenAnswer((_) async => const Left(AuthFailure('bad creds')));

    final result =
        await useCase(const LoginParams(seatNumber: 'X', password: 'y'));

    expect(result.isLeft(), isTrue);
  });

  test('trims seatNumber whitespace', () async {
    when(() => repo.login(seatNumber: 'S001', password: 'pass'))
        .thenAnswer((_) async => const Right(session));

    await useCase(const LoginParams(seatNumber: ' S001 ', password: 'pass'));

    verify(() => repo.login(seatNumber: 'S001', password: 'pass'))
        .called(1);
  });
}
