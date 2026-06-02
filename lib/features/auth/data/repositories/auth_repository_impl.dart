import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/token_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenProvider tokenProvider,
  }) : _remoteDataSource = remoteDataSource,
       _tokenProvider = tokenProvider;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenProvider _tokenProvider;

  @override
  Future<Either<Failure, AuthSession>> login({
    required String seatNumber,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        seatNumber: seatNumber,
        password: password,
      );
      await _tokenProvider.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return Right(response);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
