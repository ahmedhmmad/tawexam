import { Router } from "express";
import multer from "multer";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole, ROLE_GROUPS } from "../../middlewares/rbac.js";
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

studentsRouter.use(authenticate, requireAdminRole(ROLE_GROUPS.MANAGERS));
studentsRouter.get("/", validateQuery(studentQuerySchema), asyncHandler(controller.list));
studentsRouter.post("/", requireAdminRole(ROLE_GROUPS.MANAGERS), validateBody(studentCreateSchema), asyncHandler(controller.create));
studentsRouter.put("/:id", requireAdminRole(ROLE_GROUPS.MANAGERS), validateParams(studentIdParamsSchema), validateBody(studentUpdateSchema), asyncHandler(controller.update));
studentsRouter.delete("/:id", requireAdminRole(ROLE_GROUPS.MANAGERS), validateParams(studentIdParamsSchema), asyncHandler(controller.remove));
studentsRouter.post("/bulk-delete", requireAdminRole(ROLE_GROUPS.MANAGERS), asyncHandler(controller.bulkDelete));
studentsRouter.post("/import", requireAdminRole(ROLE_GROUPS.MANAGERS), upload.single("file"), asyncHandler(controller.import));
studentsRouter.get("/export", requireAdminRole(ROLE_GROUPS.MANAGERS), asyncHandler(controller.export));
studentsRouter.post("/:id/reset-password", requireAdminRole(ROLE_GROUPS.MANAGERS), validateParams(studentIdParamsSchema), validateBody(resetPasswordSchema), asyncHandler(controller.resetPassword));

