import { Router } from "express";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { SessionsController } from "./sessions.controller.js";
import { examIdParamsSchema, extendSessionSchema, sessionIdParamsSchema } from "./sessions.schema.js";

const controller = new SessionsController();

export const studentSessionsRouter = Router();
studentSessionsRouter.use(authenticate);
studentSessionsRouter.get("/:id/session", validateParams(examIdParamsSchema), asyncHandler(controller.getStudentSession));

export const adminSessionsRouter = Router();
adminSessionsRouter.use(authenticate, requireAdminRole(ROLE_GROUPS.SESSION_CONTROL));
adminSessionsRouter.get("/exams/:id/sessions", validateParams(examIdParamsSchema), asyncHandler(controller.listByExam));
adminSessionsRouter.post("/sessions/:id/extend", requireAdminRole(ROLE_GROUPS.SESSION_CONTROL), validateParams(sessionIdParamsSchema), validateBody(extendSessionSchema), asyncHandler(controller.extend));
adminSessionsRouter.post("/sessions/:id/force-end", requireAdminRole(ROLE_GROUPS.SESSION_CONTROL), validateParams(sessionIdParamsSchema), asyncHandler(controller.forceEnd));
// Error-recovery only: invalidate (delete) an attempt so it no longer counts.
// Restricted to managers — supervisors/teachers cannot reset attempts.
adminSessionsRouter.delete("/sessions/:id", requireAdminRole(ROLE_GROUPS.MANAGERS), validateParams(sessionIdParamsSchema), asyncHandler(controller.invalidate));
