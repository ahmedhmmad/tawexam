import type { SessionStatus } from "@prisma/client";

export interface SessionSummary {
  id: string;
  examId: string;
  studentId: string;
  attemptNumber: number;
  startedAt: Date;
  expiresAt: Date;
  remainingSeconds: number;
  status: SessionStatus;
}

