import { z } from "zod";

export const studentLoginSchema = z.object({
  seatNumber: z.string().min(1),
  password: z.string().min(1)
});

export const adminLoginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1)
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1)
});

