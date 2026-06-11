import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { MonitoringService } from "./monitoring.service.js";

const monitoringService = new MonitoringService();

export class MonitoringController {
  health(_req: Request, res: Response): Response {
    return sendSuccess(res, { namespace: "/admin/monitoring" }, "Monitoring ready");
  }

  async activeSessions(_req: Request, res: Response): Promise<Response> {
    const sessions = await monitoringService.listActiveSessions();
    return sendSuccess(res, sessions);
  }
}

export { monitoringService };

