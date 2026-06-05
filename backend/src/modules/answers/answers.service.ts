import { SessionStatus } from "@prisma/client";

import { AppError } from "../../utils/app-error.js";
import { monitoringService } from "../monitoring/monitoring.controller.js";
import { SessionsService } from "../sessions/sessions.service.js";
import { AnswersRepository } from "./answers.repository.js";

export class AnswersService {
  constructor(
    private readonly repository: AnswersRepository = new AnswersRepository(),
    private readonly sessionsService: SessionsService = new SessionsService()
  ) {}

  async saveAnswer(data: { sessionId: string; questionId: string; choiceId?: string | null }, authenticatedStudentId?: string) {
    const session = await this.sessionsService.expireIfNeeded(data.sessionId);
    if (session.status !== SessionStatus.IN_PROGRESS) {
      throw new AppError("Session is locked", 400, "SESSION_LOCKED");
    }

    if (authenticatedStudentId && session.studentId !== authenticatedStudentId) {
      throw new AppError("You do not own this session", 403, "SESSION_OWNERSHIP_DENIED");
    }

    const saved = await this.repository.upsertAnswer(data);
    monitoringService.emitEvent("answer:saved", {
      sessionId: data.sessionId,
      questionId: data.questionId
    });
    return saved;
  }

  async syncAnswers(
    items: Array<{ sessionId: string; questionId: string; choiceId?: string | null }>,
    authenticatedStudentId?: string
  ) {
    const results = [];
    for (const item of items) {
      results.push(await this.saveAnswer(item, authenticatedStudentId));
    }
    return results;
  }
}
