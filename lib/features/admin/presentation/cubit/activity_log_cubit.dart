import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../domain/entities/activity_event.dart';

class ActivityFilters extends Equatable {
  const ActivityFilters({this.examId, this.studentId, this.eventType, this.from, this.to});
  final String? examId;
  final String? studentId;
  final String? eventType;
  final DateTime? from;
  final DateTime? to;

  ActivityFilters copyWith({
    String? examId,
    String? studentId,
    String? eventType,
    DateTime? from,
    DateTime? to,
    bool clearExam = false,
    bool clearEvent = false,
    bool clearDates = false,
  }) {
    return ActivityFilters(
      examId: clearExam ? null : (examId ?? this.examId),
      studentId: studentId ?? this.studentId,
      eventType: clearEvent ? null : (eventType ?? this.eventType),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }

  @override
  List<Object?> get props => [examId, studentId, eventType, from, to];
}

sealed class ActivityLogState extends Equatable {
  const ActivityLogState();
  @override
  List<Object?> get props => [];
}

class ActivityLogLoading extends ActivityLogState {
  const ActivityLogLoading();
}

class ActivityLogError extends ActivityLogState {
  const ActivityLogError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ActivityLogLoaded extends ActivityLogState {
  const ActivityLogLoaded({required this.events, required this.total, required this.filters});
  final List<ActivityEvent> events;
  final int total;
  final ActivityFilters filters;
  @override
  List<Object?> get props => [events, total, filters];
}

class ActivityLogCubit extends Cubit<ActivityLogState> {
  ActivityLogCubit(this._dataSource) : super(const ActivityLogLoading());

  final ActivityRemoteDataSource _dataSource;
  ActivityFilters _filters = const ActivityFilters();

  ActivityFilters get filters => _filters;

  Future<void> load([ActivityFilters? filters]) async {
    if (filters != null) _filters = filters;
    emit(const ActivityLogLoading());
    await _fetch();
  }

  /// Silent refresh (for the auto-refresh timer) — keeps current list on error.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final result = await _dataSource.list(
        examId: _filters.examId,
        studentId: _filters.studentId,
        eventType: _filters.eventType,
        from: _filters.from,
        to: _filters.to,
        limit: 100,
      );
      emit(ActivityLogLoaded(events: result.rows, total: result.total, filters: _filters));
    } catch (e) {
      if (state is! ActivityLogLoaded) {
        emit(ActivityLogError(mapExceptionToFailure(e).message));
      }
    }
  }
}
