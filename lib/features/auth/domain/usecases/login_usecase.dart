import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthSession>> call(LoginParams params) {
    return _repository.login(
      seatNumber: params.seatNumber.trim(),
      password: params.password,
    );
  }
}

class LoginParams {
  const LoginParams({required this.seatNumber, required this.password});

  final String seatNumber;
  final String password;
}
