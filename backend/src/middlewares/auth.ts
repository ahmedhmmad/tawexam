import type { NextFunction, Request, Response } from "express";

import { verifyAccessToken } from "../config/jwt.js";
import { AppError } from "../utils/app-error.js";

export function authenticate(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    next(new AppError("Unauthorized", 401, "UNAUTHORIZED"));
    return;
  }

  const token = header.slice(7);

  try {
    const payload = verifyAccessToken(token);
    req.user = {
      id: payload.sub,
      subjectType: payload.subjectType,
      role: payload.role as never
    };
    next();
  } catch {
    next(new AppError("Invalid token", 401, "INVALID_TOKEN"));
  }
}

