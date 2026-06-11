import { z } from "zod";

export const examIdSchema = z.object({
  id: z.string().min(1)
});


export const analyticsQuerySchema = z.object({
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional()
});
