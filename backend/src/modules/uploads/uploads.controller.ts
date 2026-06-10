import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AuditLogService } from "../../utils/audit-log.service.js";
import { uploadsService } from "./uploads.service.js";

export class UploadsController {
  async uploadQuestionImage(req: Request, res: Response): Promise<Response> {
    const result = await uploadsService.saveQuestionImage(req.file);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "UPLOAD",
      targetEntity: "QuestionImage",
      targetId: result.url,
      payload: { originalName: req.file?.originalname, size: req.file?.size }
    });
    return sendSuccess(res, result, "Image uploaded", 201);
  }
}
