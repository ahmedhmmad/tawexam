import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { MonitoringService } from "./monitoring.service.js";

const monitoringService = new MonitoringService();

export class MonitoringController {
  health(_req: Request, res: Response): Response {
    return sendSuccess(res, { namespace: "/admin/monitoring" }, "Monitoring ready");
  }
}

export { monitoringService };

