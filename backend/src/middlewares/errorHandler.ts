import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";

import { logger } from "../config/logger.js";
import { AppError } from "../utils/app-error.js";

export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
): Response {
  if (error instanceof ZodError) {
    return res.status(400).json({
      success: false,
      data: null,
      message: "Validation failed",
      errors: error.issues.map((issue) => ({
        path: issue.path.join("."),
        message: issue.message
      }))
    });
  }

  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      data: null,
      message: error.message,
      errors: error.details ?? []
    });
  }

  logger.error("Unhandled error", { error });

  return res.status(500).json({
    success: false,
    data: null,
    message: "Internal server error",
    errors: []
  });
}

