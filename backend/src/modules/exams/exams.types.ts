export interface ExamCreateInput {
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
}

