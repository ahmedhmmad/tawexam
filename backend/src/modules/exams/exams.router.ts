import { Router } from "express";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { ExamsController } from "./exams.controller.js";
import { examCreateSchema, examIdSchema, examStatusSchema, examUpdateSchema } from "./exams.schema.js";

const controller = new ExamsController();

export const studentExamsRouter = Router();
studentExamsRouter.use(authenticate);
studentExamsRouter.get("/current", asyncHandler(controller.current));
studentExamsRouter.get("/available", asyncHandler(controller.available));
studentExamsRouter.get("/history", asyncHandler(controller.history));
studentExamsRouter.get("/:id/questions", validateParams(examIdSchema), asyncHandler(controller.studentQuestions));
studentExamsRouter.post("/:id/submit", validateParams(examIdSchema), asyncHandler(controller.submit));

export const adminExamsRouter = Router();
adminExamsRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]));
adminExamsRouter.get("/", asyncHandler(controller.list));
adminExamsRouter.post("/", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateBody(examCreateSchema), asyncHandler(controller.create));
adminExamsRouter.put("/:id", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(examIdSchema), validateBody(examUpdateSchema), asyncHandler(controller.update));
adminExamsRouter.delete("/:id", requireAdminRole([AdminRole.SUPER_ADMIN]), validateParams(examIdSchema), asyncHandler(controller.remove));
adminExamsRouter.post("/:id/duplicate", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(examIdSchema), asyncHandler(controller.duplicate));
adminExamsRouter.put("/:id/status", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(examIdSchema), validateBody(examStatusSchema), asyncHandler(controller.updateStatus));

