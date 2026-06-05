import { createLogger, format, transports } from "winston";

import { env } from "./env.js";

export const logger = createLogger({
  level: env.NODE_ENV === "production" ? env.LOG_LEVEL : "debug",
  format: format.combine(
    format.timestamp(),
    format.errors({ stack: true }),
    format.json()
  ),
  transports: [new transports.Console()]
});

