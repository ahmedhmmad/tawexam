import { SessionStatus } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export class SessionsRepository {
  findActiveSession(studentId: string, examId: string) {
    return prisma.examSession.findFirst({
      where: { studentId, examId, status: SessionStatus.IN_PROGRESS },
      include: { exam: true }
    });
  }

  countAttempts(studentId: string, examId: string) {
    return prisma.examSession.count({
      where: {
        studentId,
        examId,
        status: { in: ['SUBMITTED', 'EXPIRED', 'FORCE_ENDED'] }
      }
    });
  }

  create(data: {
    studentId: string;
    examId: string;
    attemptNumber: number;
    expiresAt: Date;
    remainingSeconds: number;
  }) {
    return prisma.examSession.create({ data });
  }

  findById(id: string) {
    return prisma.examSession.findUnique({
      where: { id },
      include: { exam: true, student: true }
    });
  }

  findByStudentAndExam(studentId: string, examId: string) {
    return prisma.examSession.findFirst({
      where: { studentId, examId },
      orderBy: { startedAt: "desc" },
      include: { exam: true, student: true }
    });
  }

  update(id: string, data: Partial<{ expiresAt: Date; remainingSeconds: number; status: SessionStatus; submittedAt: Date }>) {
    return prisma.examSession.update({ where: { id }, data });
  }

  listByExam(examId: string) {
    return prisma.examSession.findMany({
      where: { examId },
      include: { student: true },
      orderBy: { startedAt: "desc" }
    });
  }
}

