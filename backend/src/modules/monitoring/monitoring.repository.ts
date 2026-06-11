import { SessionStatus } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export class MonitoringRepository {
  /** All IN_PROGRESS sessions with the data the live dashboard displays. */
  async listActiveSessions() {
    const sessions = await prisma.examSession.findMany({
      where: { status: SessionStatus.IN_PROGRESS },
      include: {
        student: { select: { fullName: true, seatNumber: true, branch: true } },
        exam: { select: { subjectNameAr: true, subjectNameEn: true, durationMinutes: true } },
        _count: { select: { answers: { where: { choiceId: { not: null } } } } }
      },
      orderBy: { startedAt: "desc" }
    });

    return sessions.map((session) => ({
      sessionId: session.id,
      examId: session.examId,
      examName: session.exam.subjectNameAr || session.exam.subjectNameEn,
      studentName: session.student.fullName,
      seatNumber: session.student.seatNumber,
      branch: session.student.branch,
      attemptNumber: session.attemptNumber,
      startedAt: session.startedAt,
      expiresAt: session.expiresAt,
      answeredCount: session._count.answers,
      status: session.status
    }));
  }
}
