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

    const remainingSeconds = exam.durationMinutes * 60;
    const expiresAt = new Date(Date.now() + remainingSeconds * 1000);
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

  async getStudentSession(examId: string, studentId: string) {
    const session = await this.repository.findByStudentAndExam(studentId, examId);
    if (!session) {
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

