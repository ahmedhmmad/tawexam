import { Difficulty } from "@prisma/client";
import { z } from "zod";

// Relative path produced by the upload endpoint, or an absolute http(s) URL.
// Nullable so an update can explicitly clear an existing image.
const imageUrlSchema = z
  .string()
  .min(1)
  .max(2048)
  .refine(
    (value) => value.startsWith("/uploads/") || /^https?:\/\//.test(value),
    { message: "imageUrl must be an /uploads/ path or an http(s) URL" }
  )
  .nullable()
  .optional();

export const questionCreateSchema = z.object({
  text: z.string().min(1),
  imageUrl: imageUrlSchema,
  difficulty: z.nativeEnum(Difficulty),
  category: z.string().min(1),
  orderIndex: z.number().int().positive(),
  explanation: z.string().optional(),
  choices: z.array(
    z.object({
      label: z.enum(["A", "B", "C", "D"]),
      text: z.string().min(1),
      imageUrl: imageUrlSchema,
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

// question_text / choice_a / choice_b may be empty when the cell holds an
// in-cell image instead of text — text-or-image presence is enforced after
// image extraction in QuestionsService.
export const questionImportRowSchema = z.object({
  question_text: z.coerce.string().optional().default(""),
  choice_a: z.coerce.string().optional().default(""),
  choice_b: z.coerce.string().optional().default(""),
  choice_c: z.string().optional(),
  choice_d: z.string().optional(),
  correct_answer: z.enum(["A", "B", "C", "D"]),
  explanation: z.string().optional(),
  difficulty: z.enum(["easy", "medium", "hard"]),
  category: z.string().min(1),
  question_order: z.coerce.number().int().positive(),
  image_url: z.string().optional(),
  choice_a_image: z.string().optional(),
  choice_b_image: z.string().optional(),
  choice_c_image: z.string().optional(),
  choice_d_image: z.string().optional()
});

