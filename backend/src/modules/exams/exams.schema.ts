import { ExamStatus } from "@prisma/client";
import { z } from "zod";

const examBaseSchema = z.object({
  subjectNameAr: z.string().min(1),
  subjectNameEn: z.string().min(1),
  examDate: z.string().datetime(),
  startAt: z.string().datetime(),
  endAt: z.string().datetime(),
  durationMinutes: z.number().int().min(10).max(300),
  passingScore: z.number().int().min(1).max(100),
  allowedBranches: z.array(z.string().min(1)).min(1),
  maxAttempts: z.number().int().positive().default(1),
  instructions: z.string().min(1)
});

export const examCreateSchema = examBaseSchema.refine(
  (data) => new Date(data.startAt).getTime() < new Date(data.endAt).getTime(),
  { message: "startAt must be before endAt", path: ["endAt"] }
);

export const examUpdateSchema = examBaseSchema.partial();

export const examIdSchema = z.object({
  id: z.string().min(1)
});

export const examStatusSchema = z.object({
  status: z.nativeEnum(ExamStatus)
});

