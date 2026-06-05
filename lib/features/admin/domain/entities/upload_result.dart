import 'package:equatable/equatable.dart';

class UploadResult extends Equatable {
  const UploadResult({
    required this.imported,
    required this.errors,
  });

  final int imported;
  final List<RowError> errors;

  @override
  List<Object?> get props => [imported, errors];
}

class RowError extends Equatable {
  const RowError({required this.rowNumber, required this.errors});

  final int rowNumber;
  final List<String> errors;

  @override
  List<Object?> get props => [rowNumber, errors];
}
