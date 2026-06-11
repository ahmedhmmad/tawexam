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

  /**
   * Per-question right/wrong breakdown for a graded session. Only call this
   * when the exam's showAnswers flag is enabled — it exposes correct answers.
   */
  async buildAnswerBreakdown(sessionId: string) {
    const session = await this.repository.findSessionForGrading(sessionId);
    if (!session) {
      throw new AppError("Session not found", 404, "SESSION_NOT_FOUND");
    }

    const answersByQuestion = new Map(session.answers.map((answer) => [answer.questionId, answer]));

    return [...session.exam.questions]
      .sort((a, b) => a.orderIndex - b.orderIndex)
      .map((question) => {
        const correctChoice = question.choices.find((choice) => choice.isCorrect);
        const answer = answersByQuestion.get(question.id);
        const selectedChoice = answer?.choiceId
          ? question.choices.find((choice) => choice.id === answer.choiceId)
          : undefined;

        return {
          questionId: question.id,
          questionText: question.text,
          selectedAnswer: selectedChoice?.id ?? null,
          selectedAnswerText: selectedChoice?.text ?? null,
          correctAnswer: correctChoice?.id ?? null,
          correctAnswerText: correctChoice?.text ?? null,
          isCorrect: selectedChoice !== undefined && selectedChoice.id === correctChoice?.id,
          explanation: question.explanation
        };
      });
  }

  /**
   * Shapes a graded result according to the exam's visibility flags:
   * - showResults=false → no score at all, just a "results later" message
   * - showAnswers=true  → include the per-question breakdown
   */
  async shapeStudentResult(
    exam: { showResults: boolean; showAnswers: boolean },
    result: {
      sessionId: string;
      score: number;
      totalQuestions: number;
      answeredCount: number;
      correctCount: number;
      timeTakenSeconds: number;
      gradedAt: Date;
    }
  ) {
    if (!exam.showResults) {
      return {
        visible: false,
        message: "سيتم عرض النتائج لاحقاً بقرار من المشرف"
      };
    }

    return {
      visible: true,
      showAnswers: exam.showAnswers,
      sessionId: result.sessionId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      answeredCount: result.answeredCount,
      correctCount: result.correctCount,
      timeTakenSeconds: result.timeTakenSeconds,
      gradedAt: result.gradedAt,
      ...(exam.showAnswers ? { items: await this.buildAnswerBreakdown(result.sessionId) } : {})
    };
  }

  analytics(examId: string, from?: Date, to?: Date) {
    return this.repository.analytics(examId, from, to);
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

