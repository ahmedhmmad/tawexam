import { Router } from "express";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
import { MonitoringController } from "./monitoring.controller.js";

const controller = new MonitoringController();

export const monitoringRouter = Router();

monitoringRouter.get("/health", controller.health);
monitoringRouter.get(
  "/active-sessions",
  authenticate,
  requireAdminRole(ROLE_GROUPS.SESSION_CONTROL),
  asyncHandler(controller.activeSessions)
);
