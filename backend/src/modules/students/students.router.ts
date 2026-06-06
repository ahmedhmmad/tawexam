import { Router } from "express";
import multer from "multer";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { validateBody, validateParams, validateQuery } from "../../middlewares/validate.js";
import {
  resetPasswordSchema,
  studentCreateSchema,
  studentIdParamsSchema,
  studentQuerySchema,
  studentUpdateSchema
} from "./students.schema.js";
import { StudentsController } from "./students.controller.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });
const controller = new StudentsController();

export const studentsRouter = Router();

studentsRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]));
studentsRouter.get("/", validateQuery(studentQuerySchema), asyncHandler(controller.list));
studentsRouter.post("/", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateBody(studentCreateSchema), asyncHandler(controller.create));
studentsRouter.put("/:id", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(studentIdParamsSchema), validateBody(studentUpdateSchema), asyncHandler(controller.update));
studentsRouter.delete("/:id", requireAdminRole([AdminRole.SUPER_ADMIN]), validateParams(studentIdParamsSchema), asyncHandler(controller.remove));
studentsRouter.post("/bulk-delete", requireAdminRole([AdminRole.SUPER_ADMIN]), asyncHandler(controller.bulkDelete));
studentsRouter.post("/import", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), upload.single("file"), asyncHandler(controller.import));
studentsRouter.get("/export", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER, AdminRole.VIEWER]), asyncHandler(controller.export));
studentsRouter.post("/:id/reset-password", requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]), validateParams(studentIdParamsSchema), validateBody(resetPasswordSchema), asyncHandler(controller.resetPassword));

