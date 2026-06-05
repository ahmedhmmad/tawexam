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
}

