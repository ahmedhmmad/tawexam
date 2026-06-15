import { z } from "zod";

import { CLIENT_REPORTABLE_EVENTS } from "./activity-log.events.js";

/** Student self-reported event (studentId comes from the token, not the body). */
export const activityReportSchema = z.object({
  eventType: z.string().refine((v) => CLIENT_REPORTABLE_EVENTS.includes(v), {
    message: "Event type not allowed from client"
  }),
  examId: z.string().optional(),
  description: z.string().max(300).optional(),
  metadata: z.record(z.unknown()).optional(),
  deviceIdentifier: z.string().max(200).optional()
});

export const activityQuerySchema = z.object({
  examId: z.string().optional(),
  studentId: z.string().optional(),
  eventType: z.string().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(200).default(50)
});
