import { SessionStatus } from "@prisma/client";

import { redis } from "../../config/redis.js";
import { AppError } from "../../utils/app-error.js";
import { monitoringService } from "../monitoring/monitoring.controller.js";
import { ExamsRepository } from "../exams/exams.repository.js";
import { SessionsRepository } from "./sessions.repository.js";

export class SessionsService {
  constructor(
    private readonly repository: SessionsRepository = new SessionsRepository(),
    private readonly examsRepository: ExamsRepository = new ExamsRepository()
  ) {}

  async getOrCreateSession(examId: string, studentId: string) {
    const active = await this.repository.findActiveSession(studentId, examId);
    if (active) {
      return { ...active, serverTime: new Date() };
    }

    const exam = await this.examsRepository.findById(examId);
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }

    const attempts = await this.repository.countAttempts(studentId, examId);
    if (attempts >= exam.maxAttempts) {
      throw new AppError("Maximum attempts reached", 400, "MAX_ATTEMPTS_REACHED");
    }

    // Per-student exam window: a student may start any time between startAt
    // and endAt and gets the full duration. Retries stay anchored to the
    // student's FIRST session, so quitting never grants extra time. Remaining
    // time is always capped by the exam's endAt.
    const now = new Date();
    if (now.getTime() < exam.startAt.getTime()) {
      throw new AppError("Exam has not started yet", 400, "EXAM_NOT_STARTED");
    }
    if (now.getTime() >= exam.endAt.getTime()) {
      throw new AppError("Exam time has expired", 400, "EXAM_TIME_EXPIRED");
    }

    const firstSession = await this.repository.findFirstSession(studentId, examId);
    const anchor = firstSession ? firstSession.startedAt : now;
    const elapsedSeconds = Math.max(0, Math.floor((now.getTime() - anchor.getTime()) / 1000));
    const examTotalSeconds = exam.durationMinutes * 60;
    const untilEndSeconds = Math.floor((exam.endAt.getTime() - now.getTime()) / 1000);
    const remainingSeconds = Math.min(examTotalSeconds - elapsedSeconds, untilEndSeconds);

    if (remainingSeconds <= 0) {
      throw new AppError("Exam time has expired", 400, "EXAM_TIME_EXPIRED");
    }

    const expiresAt = new Date(now.getTime() + remainingSeconds * 1000);
    const session = await this.repository.create({
      studentId,
      examId,
      attemptNumber: attempts + 1,
      expiresAt,
      remainingSeconds
    });

    await redis.set(this.remainingKey(session.id), String(remainingSeconds), "EX", remainingSeconds);
    monitoringService.emitEvent("session:started", {
      sessionId: session.id,
      examId: session.examId,
      studentId: session.studentId
    });

    return { ...session, serverTime: new Date() };
  }

  async getAttemptCount(examId: string, studentId: string): Promise<number> {
    return this.repository.countAttempts(studentId, examId);
  }

  /**
   * Seconds left in the student's personal window for this exam (anchored to
   * their first session, capped by endAt). Used by exam listings so students
   * are never shown an exam they can no longer start.
   */
  async getRemainingWindowSeconds(
    exam: { id: string; startAt: Date; endAt: Date; durationMinutes: number },
    studentId: string
  ): Promise<number> {
    const now = Date.now();
    if (now >= exam.endAt.getTime()) return 0;

    const firstSession = await this.repository.findFirstSession(studentId, exam.id);
    const anchor = firstSession ? firstSession.startedAt.getTime() : now;
    const elapsedSeconds = Math.max(0, Math.floor((now - anchor) / 1000));
    const untilEndSeconds = Math.floor((exam.endAt.getTime() - now) / 1000);
    return Math.min(exam.durationMinutes * 60 - elapsedSeconds, untilEndSeconds);
  }

  async getStudentSession(examId: string, studentId: string) {
    const session = await this.repository.findByStudentAndExam(studentId, examId);
    // If no session exists, or the last session is not IN_PROGRESS (expired/submitted),
    // try to create a new one
    if (!session || session.status !== 'IN_PROGRESS') {
      return this.getOrCreateSession(examId, studentId);
    }
    return { ...session, serverTime: new Date() };
  }

  async extendSession(id: string, additionalSeconds: number) {
    const session = await this.repository.findById(id);
    if (!session) {
      throw new AppError("Session not found", 404, "SESSION_NOT_FOUND");
    }

    const nextRemaining = session.remainingSeconds + additionalSeconds;
    const expiresAt = new Date(session.expiresAt.getTime() + additionalSeconds * 1000);
    await redis.set(this.remainingKey(id), String(nextRemaining), "EX", nextRemaining);
    return this.repository.update(id, { remainingSeconds: nextRemaining, expiresAt });
  }

  async forceEndSession(id: string) {
    const session = await this.repository.findById(id);
    if (!session) {
      throw new AppError("Session not found", 404, "SESSION_NOT_FOUND");
    }

    const updated = await this.repository.update(id, {
      status: SessionStatus.FORCE_ENDED,
      submittedAt: new Date(),
      remainingSeconds: 0
    });
    await redis.del(this.remainingKey(id));
    monitoringService.emitEvent("session:ended", {
      sessionId: id,
      status: SessionStatus.FORCE_ENDED
    });
    return updated;
  }

  async listExamSessions(examId: string) {
    return this.repository.listByExam(examId);
  }

  async expireIfNeeded(sessionId: string) {
    const session = await this.repository.findById(sessionId);
    if (!session) {
      throw new AppError("Session not found", 404, "SESSION_NOT_FOUND");
    }

    if (session.status !== SessionStatus.IN_PROGRESS) {
      return session;
    }

    if (session.expiresAt.getTime() > Date.now()) {
      return session;
    }

    const updated = await this.repository.update(sessionId, {
      status: SessionStatus.EXPIRED,
      submittedAt: new Date(),
      remainingSeconds: 0
    });
    await redis.del(this.remainingKey(sessionId));
    monitoringService.emitEvent("session:ended", {
      sessionId,
      status: SessionStatus.EXPIRED
    });
    return updated;
  }

  private remainingKey(sessionId: string): string {
    return `session:${sessionId}:remaining`;
  }
}

