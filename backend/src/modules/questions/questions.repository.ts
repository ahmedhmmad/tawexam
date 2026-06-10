import { Difficulty } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export interface ChoiceInput {
  label: string;
  text: string;
  imageUrl?: string | null;
  isCorrect: boolean;
}

export interface QuestionInput {
  text: string;
  imageUrl?: string | null;
  difficulty: Difficulty;
  category: string;
  orderIndex: number;
  explanation?: string;
  choices: ChoiceInput[];
}

export class QuestionsRepository {
  listByExam(examId: string) {
    return prisma.question.findMany({
      where: { examId },
      include: { choices: true },
      orderBy: { orderIndex: "asc" }
    });
  }

  findById(id: string) {
    return prisma.question.findUnique({
      where: { id },
      include: { choices: true }
    });
  }

  create(examId: string, data: QuestionInput) {
    return prisma.question.create({
      data: {
        examId,
        text: data.text,
        imageUrl: data.imageUrl,
        difficulty: data.difficulty,
        category: data.category,
        orderIndex: data.orderIndex,
        explanation: data.explanation,
        choices: { create: data.choices }
      },
      include: { choices: true }
    });
  }

  update(id: string, data: Partial<QuestionInput>) {
    return prisma.$transaction(async (tx) => {
      if (data.choices) {
        await tx.choice.deleteMany({ where: { questionId: id } });
      }

      return tx.question.update({
        where: { id },
        data: {
          text: data.text,
          imageUrl: data.imageUrl,
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

  async replaceForExam(examId: string, data: QuestionInput[]) {
    await prisma.question.deleteMany({ where: { examId } });
    return prisma.$transaction(
      data.map((item) =>
        prisma.question.create({
          data: {
            examId,
            text: item.text,
            imageUrl: item.imageUrl,
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
