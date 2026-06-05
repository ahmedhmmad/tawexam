import { ExamStatus } from "@prisma/client";
import { z } from "zod";

export const examCreateSchema = z.object({
  subjectNameAr: z.string().min(1),
  subjectNameEn: z.string().min(1),
  examDate: z.string().datetime(),
  startAt: z.string().datetime(),
  endAt: z.string().datetime(),
  durationMinutes: z.number().int().positive(),
  passingScore: z.number().int().min(0).max(100),
  allowedBranches: z.array(z.string().min(1)).min(1),
  maxAttempts: z.number().int().positive().default(1),
  instructions: z.string().min(1)
});

export const examUpdateSchema = examCreateSchema.partial();

export const examIdSchema = z.object({
  id: z.string().min(1)
});

export const examStatusSchema = z.object({
  status: z.nativeEnum(ExamStatus)
});

