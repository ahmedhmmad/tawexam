import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { validateParams, validateQuery } from "../../middlewares/validate.js";
import { ResultsController } from "./results.controller.js";
import { analyticsQuerySchema, examIdSchema } from "./results.schema.js";

const controller = new ResultsController();

export const studentResultsRouter = Router();
studentResultsRouter.use(authenticate);
studentResultsRouter.get("/:id/result", validateParams(examIdSchema), asyncHandler(controller.studentResult));

export const adminResultsRouter = Router();
adminResultsRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]));
adminResultsRouter.get("/:id/results", validateParams(examIdSchema), validateQuery(analyticsQuerySchema), asyncHandler(controller.analytics));
adminResultsRouter.get("/:id/results/list", validateParams(examIdSchema), asyncHandler(controller.list));
adminResultsRouter.get("/:id/results/export", validateParams(examIdSchema), asyncHandler(controller.export));

