import '../../domain/entities/auth_session.dart';
import 'student_model.dart';

class AuthResponseModel extends AuthSession {
  const AuthResponseModel({
    required super.student,
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? json);
    return AuthResponseModel(
      student: StudentModel.fromJson(
        _readMap(data, 'user', fallbackKey: 'student'),
      ),
      accessToken: '${data['accessToken'] ?? data['access_token']}',
      refreshToken: _readOptionalString(
        data['refreshToken'] ?? data['refresh_token'],
      ),
    );
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> data,
    String key, {
    String? fallbackKey,
  }) {
    final raw = data[key] ?? (fallbackKey == null ? null : data[fallbackKey]);
    return Map<String, dynamic>.from(raw as Map);
  }

  static String? _readOptionalString(Object? value) {
    return value == null ? null : '$value';
  }
}
