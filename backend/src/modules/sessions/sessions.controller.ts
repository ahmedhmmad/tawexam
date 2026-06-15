import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AuditLogService } from "../../utils/audit-log.service.js";
import { SessionsService } from "./sessions.service.js";

const sessionsService = new SessionsService();

export class SessionsController {
  async getStudentSession(req: Request, res: Response): Promise<Response> {
    const session = await sessionsService.getStudentSession(req.params.id as string, req.user!.id);
    return sendSuccess(res, session);
  }

  async extend(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const session = await sessionsService.extendSession(id, req.body.additionalSeconds);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "EXTEND",
      targetEntity: "ExamSession",
      targetId: id,
      payload: { additionalSeconds: req.body.additionalSeconds }
    });
    return sendSuccess(res, session, "Session extended");
  }

  async forceEnd(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const session = await sessionsService.forceEndSession(id);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "FORCE_END",
      targetEntity: "ExamSession",
      targetId: id
    });
    return sendSuccess(res, session, "Session force ended");
  }

  /** Admin-only error recovery: invalidate an attempt so it no longer counts. */
  async invalidate(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const result = await sessionsService.invalidateAttempt(id);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "INVALIDATE_ATTEMPT",
      targetEntity: "ExamSession",
      targetId: id,
      payload: result
    });
    return sendSuccess(res, result, "Attempt invalidated");
  }

  async listByExam(req: Request, res: Response): Promise<Response> {
    const sessions = await sessionsService.listExamSessions(req.params.id as string);
    return sendSuccess(res, sessions);
  }
}
