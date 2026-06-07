import { prisma } from "../../config/prisma.js";

export class ResultsRepository {
  findBySessionId(sessionId: string) {
    return prisma.examResult.findUnique({ where: { sessionId } });
  }

  create(data: {
    sessionId: string;
    score: number;
    totalQuestions: number;
    answeredCount: number;
    correctCount: number;
    timeTakenSeconds: number;
  }) {
    return prisma.examResult.create({ data });
  }

  findSessionForGrading(sessionId: string) {
    return prisma.examSession.findUnique({
      where: { id: sessionId },
      include: {
        exam: { include: { questions: { include: { choices: true } } } },
        answers: true
      }
    });
  }

  findStudentResult(examId: string, studentId: string) {
    return prisma.examResult.findFirst({
      where: {
        session: {
          examId,
          studentId
        }
      },
      include: { session: true }
    });
  }

  async analytics(examId: string) {
    const results = await prisma.examResult.findMany({
      where: { session: { examId } },
      include: { session: { include: { answers: true, exam: { include: { questions: true } } } } }
    });

    const avg = results.length === 0 ? 0 : results.reduce((sum, item) => sum + item.score, 0) / results.length;
    const passRate =
      results.length === 0
        ? 0
        : (results.filter((item) => item.score >= item.session.exam.passingScore).length / results.length) * 100;

    return {
      averageScore: Math.round(avg),
      passRate: Math.round(passRate),
      completionRate: results.length,
      distribution: results.map((item) => item.score)
    };
  }

  listForExport(examId: string) {
    return prisma.examResult.findMany({
      where: { session: { examId } },
      include: {
        session: {
          include: { student: true }
        }
      },
      orderBy: { gradedAt: "desc" }
    });
  }

  listSessionsWithStudents(examId: string) {
    return prisma.examSession.findMany({
      where: { examId },
      include: {
        student: true,
        answers: true
      },
      orderBy: { startedAt: "desc" }
    });
  }
}

