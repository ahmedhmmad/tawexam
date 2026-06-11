import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { MonitoringController } from "./monitoring.controller.js";

const controller = new MonitoringController();

export const monitoringRouter = Router();

monitoringRouter.get("/health", controller.health);
monitoringRouter.get(
  "/active-sessions",
  authenticate,
  requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]),
  asyncHandler(controller.activeSessions)
);
