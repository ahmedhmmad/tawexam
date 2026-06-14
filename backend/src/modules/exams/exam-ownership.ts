import { AdminRole } from "@prisma/client";

import { prisma } from "../../config/prisma.js";
import { AppError } from "../../utils/app-error.js";

/** The acting admin (from req.user) used for per-row authorization. */
export interface ExamActor {
  id: string;
  role?: AdminRole;
}

export function isTeacher(actor: ExamActor | undefined): boolean {
  return actor?.role === AdminRole.TEACHER;
}

/**
 * Teachers may only act on exams they created. No-op for other roles.
 * Throws 404 if the exam is missing, 403 if a teacher doesn't own it.
 */
export async function assertExamOwnership(examId: string, actor: ExamActor | undefined): Promise<void> {
  if (!isTeacher(actor)) return;
  const exam = await prisma.exam.findUnique({
    where: { id: examId },
    select: { createdById: true }
  });
  if (!exam) {
    throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
  }
  if (exam.createdById !== actor!.id) {
    throw new AppError("You can only manage your own exams", 403, "NOT_EXAM_OWNER");
  }
}

/** Resolve a question's exam, then assert teacher ownership of that exam. */
export async function assertQuestionOwnership(
  questionId: string,
  actor: ExamActor | undefined
): Promise<void> {
  if (!isTeacher(actor)) return;
  const question = await prisma.question.findUnique({
    where: { id: questionId },
    select: { examId: true }
  });
  if (!question) {
    throw new AppError("Question not found", 404, "QUESTION_NOT_FOUND");
  }
  await assertExamOwnership(question.examId, actor);
}
