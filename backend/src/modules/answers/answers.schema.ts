import { z } from "zod";

export const saveAnswerSchema = z.object({
  sessionId: z.string().min(1),
  questionId: z.string().min(1),
  choiceId: z.string().min(1).nullable().optional()
});

export const syncAnswersSchema = z.object({
  answers: z.array(saveAnswerSchema).min(1).max(50)
});

