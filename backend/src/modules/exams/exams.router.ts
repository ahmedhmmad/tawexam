import { Router } from "express";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
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
adminExamsRouter.use(authenticate, requireAdminRole(ROLE_GROUPS.ALL_ADMIN));
adminExamsRouter.get("/", asyncHandler(controller.list));
adminExamsRouter.post("/", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateBody(examCreateSchema), asyncHandler(controller.create));
adminExamsRouter.put("/:id", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), validateBody(examUpdateSchema), asyncHandler(controller.update));
adminExamsRouter.delete("/:id", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), asyncHandler(controller.remove));
adminExamsRouter.post("/:id/duplicate", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), asyncHandler(controller.duplicate));
adminExamsRouter.put("/:id/status", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), validateBody(examStatusSchema), asyncHandler(controller.updateStatus));

