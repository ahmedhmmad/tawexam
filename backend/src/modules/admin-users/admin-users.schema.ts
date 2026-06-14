import { AdminRole } from "@prisma/client";
import { z } from "zod";

export const adminUserCreateSchema = z.object({
  username: z.string().trim().min(3).max(50),
  password: z.string().min(8).max(100),
  role: z.nativeEnum(AdminRole),
  isActive: z.boolean().optional()
});

export const adminUserUpdateSchema = z
  .object({
    username: z.string().trim().min(3).max(50).optional(),
    role: z.nativeEnum(AdminRole).optional(),
    isActive: z.boolean().optional()
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: "At least one field must be provided"
  });

export const adminUserResetPasswordSchema = z.object({
  password: z.string().min(8).max(100)
});

export const adminUserIdParamsSchema = z.object({
  id: z.string().min(1)
});
