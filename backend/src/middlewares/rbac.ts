import { AdminRole } from "@prisma/client";
import type { NextFunction, Request, Response } from "express";

import { AppError } from "../utils/app-error.js";

/**
 * Reusable role groups for the four tiered roles. Per-row scoping for TEACHER
 * (own exams only) is enforced in the services, not here — this only gates
 * which roles may reach a route at all.
 */
export const ROLE_GROUPS = {
  /** Any admin role — read-only endpoints reachable by everyone. */
  ALL_ADMIN: [AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPERVISOR, AdminRole.TEACHER],
  /** Full content/people management (students, etc.). */
  MANAGERS: [AdminRole.SUPER_ADMIN, AdminRole.ADMIN],
  /** Authors of exams & questions (teachers limited to their own). */
  EXAM_AUTHORS: [AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.TEACHER],
  /** Live monitoring + session control. */
  SESSION_CONTROL: [AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPERVISOR],
  /** Results & analytics viewers (teachers limited to their own exams). */
  RESULTS_VIEWERS: [AdminRole.SUPER_ADMIN, AdminRole.ADMIN, AdminRole.SUPERVISOR, AdminRole.TEACHER]
} as const;

export function requireAdminRole(roles: readonly AdminRole[]) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (req.user?.subjectType !== "admin" || !req.user.role || !roles.includes(req.user.role)) {
      next(new AppError("Forbidden", 403, "FORBIDDEN"));
      return;
    }
    next();
  };
}

