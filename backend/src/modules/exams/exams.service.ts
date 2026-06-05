import { ExamStatus, SessionStatus } from "@prisma/client";

import { AppError } from "../../utils/app-error.js";
import { ResultsService } from "../results/results.service.js";
import { SessionsService } from "../sessions/sessions.service.js";
import { ExamsRepository } from "./exams.repository.js";

const VALID_TRANSITIONS: Record<ExamStatus, ExamStatus[]> = {
  [ExamStatus.DRAFT]: [ExamStatus.SCHEDULED],
  [ExamStatus.SCHEDULED]: [ExamStatus.ACTIVE],
  [ExamStatus.ACTIVE]: [ExamStatus.COMPLETED],
  [ExamStatus.COMPLETED]: [ExamStatus.ARCHIVED],
  [ExamStatus.ARCHIVED]: []
};

export class ExamsService {
  constructor(
    private readonly repository: ExamsRepository = new ExamsRepository(),
    private readonly sessionsService: SessionsService = new SessionsService(),
    private readonly resultsService: ResultsService = new ResultsService()
  ) {}

  list() {
    return this.repository.list();
  }

  create(payload: {
    subjectNameAr: string;
    subjectNameEn: string;
    examDate: string;
    startAt: string;
    endAt: string;
    durationMinutes: number;
    passingScore: number;
    allowedBranches: string[];
    maxAttempts: number;
    instructions: string;
    createdById: string;
  }) {
    return this.repository.create({
      ...payload,
      examDate: new Date(payload.examDate),
      startAt: new Date(payload.startAt),
      endAt: new Date(payload.endAt)
    });
  }

  update(id: string, payload: Record<string, unknown>) {
    return this.repository.update(id, payload);
  }

  async delete(id: string) {
    const exam = await this.repository.findById(id);
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }
    if (exam.status !== ExamStatus.DRAFT) {
      throw new AppError(
        "Only DRAFT exams can be deleted",
        409,
        "EXAM_DELETE_CONFLICT"
      );
    }
    return this.repository.delete(id);
  }

  async currentForStudent(studentId: string) {
    const student = await this.repository.findStudentById(studentId);
    if (!student) {
      throw new AppError("Student not found", 404, "STUDENT_NOT_FOUND");
    }

    const exam = await this.repository.findCurrentExamForBranch(student.branch, new Date());
    if (!exam) {
      throw new AppError("No active exam available", 404, "EXAM_NOT_AVAILABLE");
    }

    return {
      id: exam.id,
      subjectNameAr: exam.subjectNameAr,
      subjectNameEn: exam.subjectNameEn,
      examDate: exam.examDate,
      startAt: exam.startAt,
      endAt: exam.endAt,
      durationMinutes: exam.durationMinutes,
      totalQuestions: exam.questions.length,
      passingScore: exam.passingScore,
      instructions: exam.instructions
    };
  }

  async studentQuestions(examId: string, studentId: string) {
    const session = await this.sessionsService.getStudentSession(examId, studentId);
    if (session.status !== SessionStatus.IN_PROGRESS) {
      throw new AppError("Session is not active", 400, "SESSION_NOT_ACTIVE");
    }

    const exam = await this.repository.findById(examId);
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }

    return exam.questions.map((question) => ({
      id: question.id,
      text: question.text,
      difficulty: question.difficulty,
      category: question.category,
      orderIndex: question.orderIndex,
      explanation: null,
      choices: question.choices.map((choice) => ({
        id: choice.id,
        label: choice.label,
        text: choice.text
      }))
    }));
  }

  duplicate(id: string, adminId: string) {
    return this.repository.duplicate(id, adminId);
  }

  async updateStatus(id: string, status: ExamStatus) {
    const exam = await this.repository.findById(id);
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }

    const allowedTransitions = VALID_TRANSITIONS[exam.status as ExamStatus] ?? [];
    if (!allowedTransitions.includes(status)) {
      throw new AppError(
        `Invalid status transition from ${exam.status} to ${status}. Allowed: ${allowedTransitions.join(", ") || "none"}`,
        400,
        "INVALID_STATUS_TRANSITION"
      );
    }

    return this.repository.update(id, { status });
  }

  async submitExam(examId: string, studentId: string) {
    const session = await this.sessionsService.getStudentSession(examId, studentId);
    const expiredSession = await this.sessionsService.expireIfNeeded(session.id);

    const finalSession =
      expiredSession.status === SessionStatus.IN_PROGRESS
        ? await this.repository.updateSessionStatus(session.id, SessionStatus.SUBMITTED, new Date())
        : expiredSession;

    return this.resultsService.gradeSession(finalSession.id);
  }
}

