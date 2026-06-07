import { ExamStatus, SessionStatus } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export class ExamsRepository {
  list() {
    return prisma.exam.findMany({
      include: {
        _count: { select: { questions: true, sessions: true } }
      },
      orderBy: { examDate: "desc" }
    });
  }

  create(data: {
    subjectNameAr: string;
    subjectNameEn: string;
    examDate: Date;
    startAt: Date;
    endAt: Date;
    durationMinutes: number;
    passingScore: number;
    allowedBranches: string[];
    maxAttempts: number;
    instructions: string;
    showResults?: boolean;
    showAnswers?: boolean;
    status?: string;
    createdById: string;
  }) {
    return prisma.exam.create({
      data: {
        subjectNameAr: data.subjectNameAr,
        subjectNameEn: data.subjectNameEn,
        examDate: data.examDate,
        startAt: data.startAt,
        endAt: data.endAt,
        durationMinutes: data.durationMinutes,
        passingScore: data.passingScore,
        allowedBranches: data.allowedBranches,
        maxAttempts: data.maxAttempts,
        instructions: data.instructions,
        showResults: data.showResults ?? false,
        showAnswers: data.showAnswers ?? false,
        status: data.status === 'ACTIVE' ? ExamStatus.ACTIVE : ExamStatus.DRAFT,
        createdById: data.createdById,
      }
    });
  }

  update(id: string, data: Record<string, unknown>) {
    return prisma.exam.update({ where: { id }, data });
  }

  delete(id: string) {
    return prisma.exam.delete({ where: { id } });
  }

  findById(id: string) {
    return prisma.exam.findUnique({
      where: { id },
      include: {
        questions: {
          include: { choices: true },
          orderBy: { orderIndex: "asc" }
        }
      }
    });
  }

  findCurrentExamForBranch(branch: string, now: Date) {
    return prisma.exam.findMany({
      where: {
        status: { in: [ExamStatus.SCHEDULED, ExamStatus.ACTIVE] },
        endAt: { gte: now },
        ...(branch ? { allowedBranches: { has: branch } } : {})
      },
      include: {
        questions: {
          include: { choices: true },
          orderBy: { orderIndex: "asc" }
        }
      },
      orderBy: { startAt: "asc" }
    });
  }

  findStudentById(studentId: string) {
    return prisma.student.findUnique({ where: { id: studentId } });
  }

  async getStudentHistory(studentId: string) {
    const sessions = await prisma.examSession.findMany({
      where: {
        studentId,
        status: { in: ['SUBMITTED', 'EXPIRED'] }
      },
      include: {
        exam: { select: { subjectNameAr: true, subjectNameEn: true } },
        result: { select: { score: true } }
      },
      orderBy: { submittedAt: 'desc' },
      take: 20
    });

    return sessions.map(s => ({
      examId: s.examId,
      subjectNameAr: s.exam.subjectNameAr,
      subjectNameEn: s.exam.subjectNameEn,
      submittedAt: s.submittedAt?.toISOString() ?? s.startedAt.toISOString(),
      score: s.result?.score ?? null,
      status: s.status
    }));
  }

  async duplicate(id: string, adminId: string) {
    const exam = await this.findById(id);
    if (!exam) {
      return null;
    }

    return prisma.exam.create({
      data: {
        subjectNameAr: `${exam.subjectNameAr} (نسخة)`,
        subjectNameEn: `${exam.subjectNameEn} (Copy)`,
        examDate: exam.examDate,
        startAt: exam.startAt,
        endAt: exam.endAt,
        durationMinutes: exam.durationMinutes,
        passingScore: exam.passingScore,
        allowedBranches: exam.allowedBranches,
        maxAttempts: exam.maxAttempts,
        status: ExamStatus.DRAFT,
        instructions: exam.instructions,
        createdById: adminId,
        questions: {
          create: exam.questions.map((question) => ({
            text: question.text,
            type: question.type,
            difficulty: question.difficulty,
            category: question.category,
            orderIndex: question.orderIndex,
            explanation: question.explanation,
            choices: {
              create: question.choices.map((choice) => ({
                label: choice.label,
                text: choice.text,
                isCorrect: choice.isCorrect
              }))
            }
          }))
        }
      }
    });
  }

  getResultByExamAndStudent(examId: string, studentId: string) {
    return prisma.examResult.findFirst({
      where: {
        session: {
          examId,
          studentId
        }
      },
      include: {
        session: true
      }
    });
  }

  updateSessionStatus(sessionId: string, status: SessionStatus, submittedAt?: Date) {
    return prisma.examSession.update({
      where: { id: sessionId },
      data: { status, submittedAt }
    });
  }

  async saveAnswersBatch(sessionId: string, answers: Record<string, string>) {
    // Upsert each answer - saves or updates existing answers for the session
    const ops = Object.entries(answers).map(([questionId, choiceId]) =>
      prisma.answer.upsert({
        where: { sessionId_questionId: { sessionId, questionId } },
        create: { sessionId, questionId, choiceId, synced: true },
        update: { choiceId, synced: true }
      })
    );
    return prisma.$transaction(ops);
  }
}
