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
  isActive: z.coerce.boolean().optional()
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
  isActive: z.union([z.boolean(), z.string()]).optional().transform((value) => {
    if (typeof value === "boolean") return value;
    return value === undefined ? true : value.toLowerCase() !== "false";
  })
});

