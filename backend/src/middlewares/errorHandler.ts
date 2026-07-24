import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
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
      error: {
        code: "VALIDATION_ERROR",
        message: "Validation failed",
        details: error.issues.map((issue) => ({
          path: issue.path.join("."),
          message: issue.message
        }))
      }
    });
  }

  // Expired/invalid JWTs (e.g. a stale refresh token) are a normal client
  // condition, not a server fault — return 401 instead of a 500.
  if (error instanceof jwt.JsonWebTokenError) {
    return res.status(401).json({
      success: false,
      error: {
        code: "INVALID_TOKEN",
        message: "Token invalid or expired"
      }
    });
  }

  if (error instanceof AppError) {
    return res.status(error.statusCode).json({
      success: false,
      error: {
        code: error.code,
        message: error.message,
        details: error.details ?? undefined
      }
    });
  }

  // Prisma unique-constraint violation — surface a clean 409 instead of a 500.
  if (typeof error === "object" && error !== null && (error as { code?: string }).code === "P2002") {
    return res.status(409).json({
      success: false,
      error: {
        code: "DUPLICATE_RECORD",
        message: "A record with these values already exists"
      }
    });
  }

  logger.error("Unhandled error", { error });

  return res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_SERVER_ERROR",
      message: "Internal server error"
    }
  });
}

