import { Router } from "express";

import { MonitoringController } from "./monitoring.controller.js";

const controller = new MonitoringController();

export const monitoringRouter = Router();

monitoringRouter.get("/health", controller.health);

