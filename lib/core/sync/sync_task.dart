import 'package:equatable/equatable.dart';

class SyncTask extends Equatable {
  const SyncTask({
    required this.id,
    required this.endpoint,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final String endpoint;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  SyncTask copyWith({int? attempts}) {
    return SyncTask(
      id: id,
      endpoint: endpoint,
      payload: payload,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'attempts': attempts,
    };
  }

  factory SyncTask.fromJson(Map<dynamic, dynamic> json) {
    return SyncTask(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      attempts: json['attempts'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, endpoint, payload, createdAt, attempts];
}
