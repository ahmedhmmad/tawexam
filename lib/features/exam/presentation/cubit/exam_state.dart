import 'package:equatable/equatable.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../auth/domain/entities/exam_session.dart';
import '../../../auth/domain/entities/student.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/exam_result.dart';
import '../../domain/entities/question.dart';

sealed class ExamState extends Equatable {
  const ExamState();

  @override
  List<Object?> get props => [];
}

class ExamInitial extends ExamState {
  const ExamInitial();
}

class ExamLoading extends ExamState {
  const ExamLoading();
}

class ExamReady extends ExamState {
  const ExamReady({
    required this.student,
    required this.session,
    required this.exam,
    required this.questions,
    required this.answers,
    required this.flagged,
    required this.currentIndex,
    required this.remaining,
    required this.syncStatus,
    this.isStarted = false,
    this.isLocked = false,
  });

  final Student student;
  final ExamSession session;
  final Exam exam;
  final List<Question> questions;
  final Map<String, String> answers;
  final Set<String> flagged;
  final int currentIndex;
  final Duration remaining;
  final SyncStatus syncStatus;
  final bool isStarted;
  final bool isLocked;

  Question get currentQuestion => questions[currentIndex];
  int get answeredCount => answers.length;
  int get unansweredCount => questions.length - answers.length;
  int get flaggedCount => flagged.length;

  ExamReady copyWith({
    Map<String, String>? answers,
    Set<String>? flagged,
    int? currentIndex,
    Duration? remaining,
    SyncStatus? syncStatus,
    bool? isStarted,
    bool? isLocked,
  }) {
    return ExamReady(
      student: student,
      session: session,
      exam: exam,
      questions: questions,
      answers: answers ?? this.answers,
      flagged: flagged ?? this.flagged,
      currentIndex: currentIndex ?? this.currentIndex,
      remaining: remaining ?? this.remaining,
      syncStatus: syncStatus ?? this.syncStatus,
      isStarted: isStarted ?? this.isStarted,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  List<Object?> get props {
    return [
      student,
      session,
      exam,
      questions,
      answers,
      flagged,
      currentIndex,
      remaining,
      syncStatus,
      isStarted,
      isLocked,
    ];
  }
}

class ExamTimerExpired extends ExamState {
  const ExamTimerExpired(this.ready);

  final ExamReady ready;

  @override
  List<Object?> get props => [ready];
}

class ExamSubmitting extends ExamState {
  const ExamSubmitting(this.ready);

  final ExamReady ready;

  @override
  List<Object?> get props => [ready];
}

class ExamSubmitted extends ExamState {
  const ExamSubmitted(this.result);

  final ExamResult result;

  @override
  List<Object?> get props => [result];
}

class ExamError extends ExamState {
  const ExamError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
