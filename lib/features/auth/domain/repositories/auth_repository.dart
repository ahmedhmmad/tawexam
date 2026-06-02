import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, AuthSession>> login({
    required String seatNumber,
    required String password,
  });
}
