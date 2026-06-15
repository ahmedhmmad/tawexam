import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
import { validateBody, validateQuery } from "../../middlewares/validate.js";
import { ActivityLogController } from "./activity-log.controller.js";
import { activityQuerySchema, activityReportSchema } from "./activity-log.schema.js";

const controller = new ActivityLogController();

// Student-facing: report a client-side activity event.
export const studentActivityRouter = Router();
studentActivityRouter.use(authenticate);
studentActivityRouter.post("/", validateBody(activityReportSchema), asyncHandler(controller.report));

// Admin-facing: query / export / delete activity logs.
export const adminActivityRouter = Router();
adminActivityRouter.use(authenticate, requireAdminRole(ROLE_GROUPS.ALL_ADMIN));
adminActivityRouter.get("/", validateQuery(activityQuerySchema), asyncHandler(controller.list));
adminActivityRouter.get("/export", validateQuery(activityQuerySchema), asyncHandler(controller.export));
// Only SUPER_ADMIN may delete logs.
adminActivityRouter.delete("/", requireAdminRole([AdminRole.SUPER_ADMIN]), asyncHandler(controller.remove));
