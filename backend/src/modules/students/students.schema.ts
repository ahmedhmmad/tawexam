import { z } from "zod";

export const studentCreateSchema = z.object({
  seatNumber: z.string().min(1),
  fullName: z.string().min(1),
  password: z.string().min(1),
  mobileNo: z.string().default(""),
  branch: z.string().default(""),
  schoolName: z.string().default(""),
  isActive: z.boolean().default(true)
});

export const studentUpdateSchema = z.object({
  seatNumber: z.string().min(1).optional(),
  fullName: z.string().min(1).optional(),
  password: z.string().min(1).optional(),
  mobileNo: z.string().optional(),
  branch: z.string().optional(),
  schoolName: z.string().optional(),
  isActive: z.boolean().optional()
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
  password: z.string().min(1).optional()
});

// Excel import: columns are id, name, mobile_no
export const studentImportRowSchema = z.object({
  id: z.coerce.string().min(1),
  name: z.string().min(1),
  mobile_no: z.coerce.string().min(1)
});
