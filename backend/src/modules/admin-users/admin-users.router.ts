import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { AdminUsersController } from "./admin-users.controller.js";
import {
  adminUserCreateSchema,
  adminUserIdParamsSchema,
  adminUserResetPasswordSchema,
  adminUserUpdateSchema
} from "./admin-users.schema.js";

const controller = new AdminUsersController();

export const adminUsersRouter = Router();

// Admin-user management is restricted to SUPER_ADMIN only.
adminUsersRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN]));
adminUsersRouter.get("/", asyncHandler(controller.list));
adminUsersRouter.post("/", validateBody(adminUserCreateSchema), asyncHandler(controller.create));
adminUsersRouter.put(
  "/:id",
  validateParams(adminUserIdParamsSchema),
  validateBody(adminUserUpdateSchema),
  asyncHandler(controller.update)
);
adminUsersRouter.post(
  "/:id/reset-password",
  validateParams(adminUserIdParamsSchema),
  validateBody(adminUserResetPasswordSchema),
  asyncHandler(controller.resetPassword)
);
adminUsersRouter.delete("/:id", validateParams(adminUserIdParamsSchema), asyncHandler(controller.remove));
