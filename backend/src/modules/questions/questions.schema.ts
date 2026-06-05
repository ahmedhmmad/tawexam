import { Difficulty } from "@prisma/client";
import { z } from "zod";

export const questionCreateSchema = z.object({
  text: z.string().min(1),
  difficulty: z.nativeEnum(Difficulty),
  category: z.string().min(1),
  orderIndex: z.number().int().positive(),
  explanation: z.string().optional(),
  choices: z.array(
    z.object({
      label: z.enum(["A", "B", "C", "D"]),
      text: z.string().min(1),
      isCorrect: z.boolean()
    })
  ).length(4).refine(
    (choices) => choices.filter((c) => c.isCorrect).length === 1,
    { message: "Exactly one choice must be marked as correct" }
  )
});

export const questionUpdateSchema = questionCreateSchema.partial();

export const questionIdSchema = z.object({
  id: z.string().min(1)
});

export const examIdSchema = z.object({
  id: z.string().min(1)
});

export const importModeSchema = z.object({
  mode: z.enum(["append", "replace"]).default("append")
});

export const questionImportRowSchema = z.object({
  question_text: z.string().min(1),
  choice_a: z.string().min(1),
  choice_b: z.string().min(1),
  choice_c: z.string().optional(),
  choice_d: z.string().optional(),
  correct_answer: z.enum(["A", "B", "C", "D"]),
  explanation: z.string().optional(),
  difficulty: z.enum(["easy", "medium", "hard"]),
  category: z.string().min(1),
  question_order: z.coerce.number().int().positive()
});

