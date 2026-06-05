import { z } from "zod";

export const examIdParamsSchema = z.object({
  id: z.string().min(1)
});

export const sessionIdParamsSchema = z.object({
  id: z.string().min(1)
});

export const extendSessionSchema = z.object({
  additionalSeconds: z.coerce.number().int().positive()
});

