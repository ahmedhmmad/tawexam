import { ExamStatus, SessionStatus } from "@prisma/client";

import { AppError } from "../../utils/app-error.js";
import { ResultsService } from "../results/results.service.js";
import { SessionsService } from "../sessions/sessions.service.js";
import { ExamsRepository } from "./exams.repository.js";

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
    showResults?: boolean;
    showAnswers?: boolean;
    status?: string;
    createdById: string;
  }) {
    return this.repository.create({
      ...payload,
      examDate: new Date(payload.examDate),
      startAt: new Date(payload.startAt),
      endAt: new Date(payload.endAt),
      showResults: payload.showResults ?? false,
      showAnswers: payload.showAnswers ?? false,
      status: payload.status === 'ACTIVE' ? 'ACTIVE' : undefined
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
    return this.repository.delete(id);
  }

  async currentForStudent(studentId: string) {
    const student = await this.repository.findStudentById(studentId);
    if (!student) {
      throw new AppError("Student not found", 404, "STUDENT_NOT_FOUND");
    }

    const exams = await this.repository.findCurrentExamForBranch(student.branch, new Date());
    if (!exams || exams.length === 0) {
      throw new AppError("No active exam available", 404, "EXAM_NOT_AVAILABLE");
    }


    const result = [];

    for (const exam of exams) {
      // Check if student has exhausted attempts (only for ACTIVE exams)
      const attemptCount = await this.sessionsService.getAttemptCount(exam.id, studentId);
      if (exam.status === 'ACTIVE' && attemptCount >= exam.maxAttempts) {
        continue; // Skip this exam, student used all attempts
      }

      // Skip ACTIVE exams the student can no longer start: endAt passed, or
      // their personal window (anchored to their first session) is used up
      if (exam.status === 'ACTIVE') {
        const remaining = await this.sessionsService.getRemainingWindowSeconds(exam, studentId);
        if (remaining <= 0) {
          continue;
        }
      }

      result.push({
        id: exam.id,
        subjectNameAr: exam.subjectNameAr,
        subjectNameEn: exam.subjectNameEn,
        examDate: exam.examDate,
        startAt: exam.startAt,
        endAt: exam.endAt,
        durationMinutes: exam.durationMinutes,
        totalQuestions: exam.questions.length,
        passingScore: exam.passingScore,
        instructions: exam.instructions,
        maxAttempts: exam.maxAttempts,
        currentAttempt: attemptCount + 1,
        status: exam.status
      });
    }

    if (result.length === 0) {
      throw new AppError("No active exam available", 404, "EXAM_NOT_AVAILABLE");
    }

    // Always return a single object (first available exam)
    // The mobile app's exam flow works with one exam at a time
    return result[0];
  }

  async studentHistory(studentId: string) {
    return this.repository.getStudentHistory(studentId);
  }

  async availableForStudent(studentId: string) {
    const student = await this.repository.findStudentById(studentId);
    if (!student) {
      throw new AppError("Student not found", 404, "STUDENT_NOT_FOUND");
    }

    const exams = await this.repository.findCurrentExamForBranch(student.branch, new Date());
    if (!exams || exams.length === 0) {
      return [];
    }


    const result = [];

    for (const exam of exams) {
      const attemptCount = await this.sessionsService.getAttemptCount(exam.id, studentId);
      if (exam.status === 'ACTIVE' && attemptCount >= exam.maxAttempts) {
        continue;
      }
      // Skip ACTIVE exams the student can no longer start: endAt passed, or
      // their personal window (anchored to their first session) is used up
      if (exam.status === 'ACTIVE') {
        const remaining = await this.sessionsService.getRemainingWindowSeconds(exam, studentId);
        if (remaining <= 0) {
          continue;
        }
      }

      result.push({
        id: exam.id,
        subjectNameAr: exam.subjectNameAr,
        subjectNameEn: exam.subjectNameEn,
        examDate: exam.examDate,
        startAt: exam.startAt,
        endAt: exam.endAt,
        durationMinutes: exam.durationMinutes,
        totalQuestions: exam.questions.length,
        passingScore: exam.passingScore,
        instructions: exam.instructions,
        maxAttempts: exam.maxAttempts,
        currentAttempt: attemptCount + 1,
        status: exam.status
      });
    }

    return result;
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
      imageUrl: question.imageUrl,
      difficulty: question.difficulty,
      category: question.category,
      orderIndex: question.orderIndex,
      explanation: null,
      choices: question.choices.map((choice) => ({
        id: choice.id,
        label: choice.label,
        text: choice.text,
        imageUrl: choice.imageUrl
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
    // Allow any status transition (admins can move freely)
    return this.repository.update(id, { status });
  }

  async submitExam(examId: string, studentId: string, answers?: Record<string, string>) {
    const session = await this.sessionsService.getStudentSession(examId, studentId);
    const expiredSession = await this.sessionsService.expireIfNeeded(session.id);

    // Save answers from client before grading (ensures answers aren't lost if sync failed)
    if (answers && Object.keys(answers).length > 0) {
      await this.repository.saveAnswersBatch(session.id, answers);
    }

    const finalSession =
      expiredSession.status === SessionStatus.IN_PROGRESS
        ? await this.repository.updateSessionStatus(session.id, SessionStatus.SUBMITTED, new Date())
        : expiredSession;

    const result = await this.resultsService.gradeSession(finalSession.id);

    // The submit response must obey the same visibility rules as the result
    // endpoint — otherwise it leaks the score when showResults is disabled.
    const exam = await this.repository.findById(examId);
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }
    return this.resultsService.shapeStudentResult(exam, result);
  }
}

