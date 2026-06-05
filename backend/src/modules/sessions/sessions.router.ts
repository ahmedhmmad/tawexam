import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { SessionsController } from "./sessions.controller.js";
import { examIdParamsSchema, extendSessionSchema, sessionIdParamsSchema } from "./sessions.schema.js";

const controller = new SessionsController();

export const studentSessionsRouter = Router();
studentSessionsRouter.use(authenticate);
studentSessionsRouter.get("/:id/session", validateParams(examIdParamsSchema), asyncHandler(controller.getStudentSession));

export const adminSessionsRouter = Router();
adminSessionsRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]));
adminSessionsRouter.get("/exams/:id/sessions", validateParams(examIdParamsSchema), asyncHandler(controller.listByExam));
adminSessionsRouter.post("/sessions/:id/extend", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(sessionIdParamsSchema), validateBody(extendSessionSchema), asyncHandler(controller.extend));
adminSessionsRouter.post("/sessions/:id/force-end", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(sessionIdParamsSchema), asyncHandler(controller.forceEnd));
