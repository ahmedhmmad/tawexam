import '../../domain/entities/upload_result.dart';

class UploadResultModel extends UploadResult {
  const UploadResultModel({required super.imported, required super.errors});

  factory UploadResultModel.fromJson(Map<String, dynamic> json) =>
      UploadResultModel(
        imported: json['imported'] as int? ?? 0,
        errors: (json['errors'] as List? ?? []).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return RowError(
            rowNumber: m['rowNumber'] as int? ?? 0,
            errors: (m['errors'] as List? ?? []).map((s) => '$s').toList(),
          );
        }).toList(),
      );
}
