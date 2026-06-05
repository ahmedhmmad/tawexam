import { prisma } from "../../config/prisma.js";

export class AnswersRepository {
  upsertAnswer(data: {
    sessionId: string;
    questionId: string;
    choiceId?: string | null;
  }) {
    return prisma.answer.upsert({
      where: {
        sessionId_questionId: {
          sessionId: data.sessionId,
          questionId: data.questionId
        }
      },
      update: {
        choiceId: data.choiceId ?? null,
        synced: true,
        savedAt: new Date()
      },
      create: {
        sessionId: data.sessionId,
        questionId: data.questionId,
        choiceId: data.choiceId ?? null,
        synced: true
      }
    });
  }
}

