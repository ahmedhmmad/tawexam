import { z } from "zod";

export const studentCreateSchema = z.object({
  seatNumber: z.string().min(1),
  fullName: z.string().min(1),
  password: z.string().min(8),
  branch: z.string().min(1),
  schoolName: z.string().min(1),
  isActive: z.boolean().default(true)
});

export const studentUpdateSchema = studentCreateSchema.partial().extend({
  password: z.string().min(8).optional()
});

export const studentQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().optional(),
  branch: z.string().optional(),
  isActive: z.preprocess((value) => {
    if (value === undefined || value === "") return undefined;
    if (typeof value === "boolean") return value;
    return `${value}`.toLowerCase() === "true";
  }, z.boolean().optional())
});

export const studentIdParamsSchema = z.object({
  id: z.string().min(1)
});

export const resetPasswordSchema = z.object({
  password: z.string().min(8).optional()
});

export const studentImportRowSchema = z.object({
  seatNumber: z.string().min(1),
  fullName: z.string().min(1),
  password: z.string().min(8),
  branch: z.string().min(1),
  schoolName: z.string().min(1),
  isActive: z.preprocess((value) => {
    if (value === undefined || value === "") return true;
    if (typeof value === "boolean") return value;
    return `${value}`.toLowerCase() !== "false";
  }, z.boolean())
});
