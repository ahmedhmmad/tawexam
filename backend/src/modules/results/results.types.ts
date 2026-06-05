export interface StudentResultSummary {
  sessionId: string;
  score: number;
  totalQuestions: number;
  answeredCount: number;
  correctCount: number;
  timeTakenSeconds: number;
  gradedAt: Date;
}

