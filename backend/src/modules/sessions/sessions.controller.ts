import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { SessionsService } from "./sessions.service.js";

const sessionsService = new SessionsService();

export class SessionsController {
  async getStudentSession(req: Request, res: Response): Promise<Response> {
    const session = await sessionsService.getStudentSession(req.params.id as string, req.user!.id);
    return sendSuccess(res, session);
  }

  async extend(req: Request, res: Response): Promise<Response> {
    const session = await sessionsService.extendSession(req.params.id as string, req.body.additionalSeconds);
    return sendSuccess(res, session, "Session extended");
  }

  async forceEnd(req: Request, res: Response): Promise<Response> {
    const session = await sessionsService.forceEndSession(req.params.id as string);
    return sendSuccess(res, session, "Session force ended");
  }

  async listByExam(req: Request, res: Response): Promise<Response> {
    const sessions = await sessionsService.listExamSessions(req.params.id as string);
    return sendSuccess(res, sessions);
  }
}
