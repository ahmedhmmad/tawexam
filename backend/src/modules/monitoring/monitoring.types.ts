export interface MonitoringEvents {
  "session:started": {
    sessionId: string;
    examId: string;
    studentId: string;
  };
  "answer:saved": {
    sessionId: string;
    questionId: string;
  };
  "session:ended": {
    sessionId: string;
    status: string;
  };
  "activity:new": {
    id: string;
    eventType: string;
    studentId: string | null;
    examId: string | null;
    description: string | null;
    createdAt: string;
  };
}

