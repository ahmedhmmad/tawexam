import { Difficulty } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export class QuestionsRepository {
  listByExam(examId: string) {
    return prisma.question.findMany({
      where: { examId },
      include: { choices: true },
      orderBy: { orderIndex: "asc" }
    });
  }

  create(examId: string, data: {
    text: string;
    difficulty: Difficulty;
    category: string;
    orderIndex: number;
    explanation?: string;
    choices: Array<{ label: string; text: string; isCorrect: boolean }>;
  }) {
    return prisma.question.create({
      data: {
        examId,
        text: data.text,
        difficulty: data.difficulty,
        category: data.category,
        orderIndex: data.orderIndex,
        explanation: data.explanation,
        choices: { create: data.choices }
      },
      include: { choices: true }
    });
  }

  update(id: string, data: Partial<{
    text: string;
    difficulty: Difficulty;
    category: string;
    orderIndex: number;
    explanation?: string;
    choices: Array<{ label: string; text: string; isCorrect: boolean }>;
  }>) {
    return prisma.$transaction(async (tx) => {
      if (data.choices) {
        await tx.choice.deleteMany({ where: { questionId: id } });
      }

      return tx.question.update({
        where: { id },
        data: {
          text: data.text,
          difficulty: data.difficulty,
          category: data.category,
          orderIndex: data.orderIndex,
          explanation: data.explanation,
          choices: data.choices ? { create: data.choices } : undefined
        },
        include: { choices: true }
      });
    });
  }

  delete(id: string) {
    return prisma.question.delete({ where: { id } });
  }

  async replaceForExam(
    examId: string,
    data: Array<{
      text: string;
      difficulty: Difficulty;
      category: string;
      orderIndex: number;
      explanation?: string;
      choices: Array<{ label: string; text: string; isCorrect: boolean }>;
    }>
  ) {
    await prisma.question.deleteMany({ where: { examId } });
    return prisma.$transaction(
      data.map((item) =>
        prisma.question.create({
          data: {
            examId,
            text: item.text,
            difficulty: item.difficulty,
            category: item.category,
            orderIndex: item.orderIndex,
            explanation: item.explanation,
            choices: { create: item.choices }
          }
        })
      )
    );
  }
}

