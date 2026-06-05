import { z } from "zod";

export const monitoringParamsSchema = z.object({
  examId: z.string().min(1)
});

