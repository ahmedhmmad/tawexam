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
      // Latest attempt wins — without ordering, multi-attempt students got an
      // arbitrary attempt's result.
      orderBy: { gradedAt: "desc" },
      include: { session: true }
    });
  }

  async analytics(examId: string, from?: Date, to?: Date) {
    const startedAt = from || to ? { gte: from, lte: to } : undefined;

    const [results, totalAttempts] = await Promise.all([
      prisma.examResult.findMany({
        where: { session: { examId, ...(startedAt ? { startedAt } : {}) } },
        include: { session: { include: { exam: { select: { passingScore: true } } } } }
      }),
      prisma.examSession.count({
        where: { examId, ...(startedAt ? { startedAt } : {}) }
      })
    ]);

    const avg = results.length === 0 ? 0 : results.reduce((sum, item) => sum + item.score, 0) / results.length;
    const passRate =
      results.length === 0
        ? 0
        : (results.filter((item) => item.score >= item.session.exam.passingScore).length / results.length) * 100;
    const completionRate = totalAttempts === 0 ? 0 : (results.length / totalAttempts) * 100;

    return {
      averageScore: Math.round(avg),
      passRate: Math.round(passRate),
      // Percentage of started sessions that ended up graded
      completionRate: Math.round(completionRate),
      totalAttempts,
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

