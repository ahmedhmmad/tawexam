import type { Request } from "express";
import rateLimit from "express-rate-limit";
import { RedisStore } from "rate-limit-redis";

import { redis } from "../config/redis.js";

function buildStore(prefix: string) {
  return new RedisStore({
    prefix,
    sendCommand: (...args: string[]) =>
      redis.call(args[0], ...args.slice(1)) as Promise<any>
  });
}

export const globalRateLimiter = rateLimit({
  windowMs: 60_000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
  store: buildStore("rl:global:")
});

export const studentLoginRateLimiter = rateLimit({
  windowMs: 15 * 60_000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  store: buildStore("rl:student-login:"),
  keyGenerator: (req: Request) => (req.body as { seatNumber?: string })?.seatNumber ?? req.ip ?? "unknown"
});

export const adminLoginRateLimiter = rateLimit({
  windowMs: 15 * 60_000,
  limit: 3,
  standardHeaders: true,
  legacyHeaders: false,
  store: buildStore("rl:admin-login:")
});
