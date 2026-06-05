export interface AnswerSyncPayload {
  sessionId: string;
  questionId: string;
  choiceId?: string | null;
}

