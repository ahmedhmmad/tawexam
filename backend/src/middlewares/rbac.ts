import type { AdminRole } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import { AppError } from "../utils/app-error.js";

export function requireAdminRole(roles: AdminRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (req.user?.subjectType !== "admin" || !req.user.role || !roles.includes(req.user.role)) {
      next(new AppError("Forbidden", 403, "FORBIDDEN"));
      return;
    }
    next();
  };
}

