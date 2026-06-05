import { Router } from "express";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { adminLoginRateLimiter, studentLoginRateLimiter } from "../../middlewares/rateLimiter.js";
import { validateBody } from "../../middlewares/validate.js";
import { AuthController } from "./auth.controller.js";
import { adminLoginSchema, refreshTokenSchema, studentLoginSchema } from "./auth.schema.js";

const controller = new AuthController();

export const studentAuthRouter = Router();
studentAuthRouter.post("/student/login", studentLoginRateLimiter, validateBody(studentLoginSchema), asyncHandler(controller.studentLogin));
studentAuthRouter.post("/refresh", validateBody(refreshTokenSchema), asyncHandler(controller.refresh));
studentAuthRouter.post("/logout", validateBody(refreshTokenSchema), asyncHandler(controller.logout));

export const adminAuthRouter = Router();
adminAuthRouter.post("/login", adminLoginRateLimiter, validateBody(adminLoginSchema), asyncHandler(controller.adminLogin));

