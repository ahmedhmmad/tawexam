import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._loginUseCase) : super(const AuthInitial());

  final LoginUseCase _loginUseCase;

  Future<void> login({
    required String seatNumber,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      LoginParams(seatNumber: seatNumber, password: password),
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (session) =>
          emit(AuthSuccess(student: session.student, session: session.session)),
    );
  }
}
