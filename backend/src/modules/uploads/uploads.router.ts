import type { NextFunction, Request, Response } from "express";
import { Router } from "express";
import multer from "multer";
import { AdminRole } from "@prisma/client";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { requireAdminRole } from "../../middlewares/rbac.js";
import { AppError } from "../../utils/app-error.js";
import { UploadsController } from "./uploads.controller.js";
import { ALLOWED_IMAGE_MIME_TYPES, MAX_IMAGE_BYTES } from "./uploads.service.js";

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_IMAGE_BYTES },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(new AppError("Unsupported image type. Allowed: PNG, JPG, JPEG, WEBP", 400, "INVALID_IMAGE_TYPE"));
      return;
    }
    cb(null, true);
  }
});

// Translate multer's own errors (e.g. size limit) into the standard error shape
function uploadSingleImage(req: Request, res: Response, next: NextFunction): void {
  upload.single("file")(req, res, (error: unknown) => {
    if (error instanceof multer.MulterError && error.code === "LIMIT_FILE_SIZE") {
      next(new AppError("Image exceeds the 2MB size limit", 400, "FILE_TOO_LARGE"));
      return;
    }
    next(error ?? undefined);
  });
}

const controller = new UploadsController();

export const uploadsRouter = Router();
uploadsRouter.use(authenticate, requireAdminRole([AdminRole.SUPER_ADMIN, AdminRole.EXAM_MANAGER]));
uploadsRouter.post("/question-image", uploadSingleImage, asyncHandler(controller.uploadQuestionImage));
