import xlsx from "xlsx";

import { AppError } from "../../utils/app-error.js";
import { ResultsRepository } from "./results.repository.js";

export class ResultsService {
  constructor(private readonly repository: ResultsRepository = new ResultsRepository()) {}

  async gradeSession(sessionId: string) {
    const existing = await this.repository.findBySessionId(sessionId);
    if (existing) {
      return existing;
    }

    const session = await this.repository.findSessionForGrading(sessionId);
    if (!session) {
      throw new AppError("Session not found", 404, "SESSION_NOT_FOUND");
    }

    const questionMap = new Map(
      session.exam.questions.map((question) => [
        question.id,
        question.choices.find((choice) => choice.isCorrect)?.id ?? null
      ])
    );

    const answeredCount = session.answers.filter((answer) => answer.choiceId !== null).length;
    const correctCount = session.answers.filter((answer) => questionMap.get(answer.questionId) === answer.choiceId).length;
    const totalQuestions = session.exam.questions.length;
    const score = totalQuestions === 0 ? 0 : Math.round((correctCount / totalQuestions) * 100);
    const timeTakenSeconds = Math.max(
      0,
      Math.round((new Date(session.submittedAt ?? new Date()).getTime() - session.startedAt.getTime()) / 1000)
    );

    return this.repository.create({
      sessionId,
      score,
      totalQuestions,
      answeredCount,
      correctCount,
      timeTakenSeconds
    });
  }

  async getStudentResult(examId: string, studentId: string) {
    const result = await this.repository.findStudentResult(examId, studentId);
    if (!result) {
      throw new AppError("Result not found", 404, "RESULT_NOT_FOUND");
    }

    return {
      sessionId: result.sessionId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      answeredCount: result.answeredCount,
      correctCount: result.correctCount,
      timeTakenSeconds: result.timeTakenSeconds,
      gradedAt: result.gradedAt
    };
  }

  analytics(examId: string) {
    return this.repository.analytics(examId);
  }

  async listResults(examId: string) {
    // Get graded results
    const graded = await this.repository.listForExport(examId);

    // Also get all sessions (including ungraded/in-progress)
    const sessions = await this.repository.listSessionsWithStudents(examId);

    // Map by sessionId (each attempt has its own result)
    const gradedMap = new Map(graded.map(r => [r.sessionId, r]));

    return sessions.map(s => {
      const result = gradedMap.get(s.id);
      return {
        sessionId: s.id,
        attemptNumber: s.attemptNumber,
        studentName: s.student.fullName,
        seatNumber: s.student.seatNumber,
        branch: s.student.branch,
        score: result?.score ?? null,
        totalQuestions: result?.totalQuestions ?? 0,
        correctCount: result?.correctCount ?? 0,
        answeredCount: result?.answeredCount ?? s.answers.length,
        timeTakenSeconds: result?.timeTakenSeconds ?? 0,
        status: s.status,
        gradedAt: result?.gradedAt ?? null,
        startedAt: s.startedAt
      };
    });
  }

  async exportExamResults(examId: string): Promise<Buffer> {
    const results = await this.repository.listForExport(examId);
    const workbook = xlsx.utils.book_new();
    const sheet = xlsx.utils.json_to_sheet(
      results.map((result) => ({
        studentName: result.session.student.fullName,
        seatNumber: result.session.student.seatNumber,
        score: result.score,
        totalQuestions: result.totalQuestions,
        answeredCount: result.answeredCount,
        correctCount: result.correctCount,
        timeTakenSeconds: result.timeTakenSeconds,
        gradedAt: result.gradedAt.toISOString()
      }))
    );
    xlsx.utils.book_append_sheet(workbook, sheet, "Results");
    return xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
  }
}

