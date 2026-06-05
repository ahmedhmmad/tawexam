import { z } from "zod";

export const examIdSchema = z.object({
  id: z.string().min(1)
});

