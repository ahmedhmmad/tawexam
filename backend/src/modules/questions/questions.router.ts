import { Router } from "express";
import multer from "multer";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { QuestionsController } from "./questions.controller.js";
import {
  examIdSchema,
  importModeSchema,
  questionCreateSchema,
  questionIdSchema,
  questionUpdateSchema
} from "./questions.schema.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
const controller = new QuestionsController();

export const questionsRouter = Router();
questionsRouter.use(authenticate, requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS));
questionsRouter.get("/exams/:id/questions", validateParams(examIdSchema), asyncHandler(controller.list));
questionsRouter.post("/exams/:id/questions", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), validateBody(questionCreateSchema), asyncHandler(controller.create));
questionsRouter.put("/questions/:id", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(questionIdSchema), validateBody(questionUpdateSchema), asyncHandler(controller.update));
questionsRouter.delete("/questions/:id", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(questionIdSchema), asyncHandler(controller.remove));
questionsRouter.post("/exams/:id/questions/validate", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), upload.single("file"), asyncHandler(controller.validateImport));
questionsRouter.post("/exams/:id/questions/import", requireAdminRole(ROLE_GROUPS.EXAM_AUTHORS), validateParams(examIdSchema), upload.single("file"), validateBody(importModeSchema), asyncHandler(controller.importQuestions));
questionsRouter.get("/exams/:id/questions/template", validateParams(examIdSchema), asyncHandler(controller.template));

