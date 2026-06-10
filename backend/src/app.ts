import http from "node:http";

import compression from "compression";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { Server } from "socket.io";

import { env } from "./config/env.js";
import { logger } from "./config/logger.js";
import { setSocketServer } from "./config/socket.js";
import { requestId } from "./middlewares/requestId.js";
import { globalRateLimiter } from "./middlewares/rateLimiter.js";
import { errorHandler } from "./middlewares/errorHandler.js";
import { adminAuthRouter, studentAuthRouter } from "./modules/auth/auth.router.js";
import { answersRouter } from "./modules/answers/answers.router.js";
import { adminExamsRouter, studentExamsRouter } from "./modules/exams/exams.router.js";
import { monitoringRouter } from "./modules/monitoring/monitoring.router.js";
import { monitoringService } from "./modules/monitoring/monitoring.controller.js";
import { questionsRouter } from "./modules/questions/questions.router.js";
import { adminResultsRouter, studentResultsRouter } from "./modules/results/results.router.js";
import { adminSessionsRouter, studentSessionsRouter } from "./modules/sessions/sessions.router.js";
import { studentsRouter } from "./modules/students/students.router.js";
import { uploadsRouter } from "./modules/uploads/uploads.router.js";
import { AppError } from "./utils/app-error.js";
import { sendSuccess } from "./utils/api-response.js";

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN,
    credentials: true
  }
});

setSocketServer(io);
monitoringService.getNamespace().on("connection", (socket) => {
  monitoringService.handleConnection(socket);
});

app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(requestId);
app.use(compression());
app.use(helmet());
app.use(cors({ origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN, credentials: true }));
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));
app.use(morgan("combined", { stream: { write: (message) => logger.info(message.trim()) } }));

// Static question/choice images. Mounted before the rate limiter so a page of
// image-heavy questions doesn't exhaust the per-IP API budget. Filenames are
// immutable UUIDs, so long cache lifetimes are safe.
app.use(
  "/uploads",
  (_req, res, next) => {
    res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
    next();
  },
  express.static(env.UPLOAD_DIR, { maxAge: "30d", immutable: true })
);

app.use(globalRateLimiter);

app.get("/health", (_req, res) => {
  res.setHeader("Cache-Control", "no-cache");
  return sendSuccess(res, { status: "ok" });
});

app.use(`${env.API_PREFIX}/auth`, studentAuthRouter);
app.use(`${env.API_PREFIX}/admin/auth`, adminAuthRouter);
app.use(`${env.API_PREFIX}/admin/students`, studentsRouter);
app.use(`${env.API_PREFIX}/answers`, answersRouter);
app.use(`${env.API_PREFIX}/exam`, studentExamsRouter);
app.use(`${env.API_PREFIX}/exam`, studentSessionsRouter);
app.use(`${env.API_PREFIX}/exam`, studentResultsRouter);
app.use(`${env.API_PREFIX}/admin/exams`, adminExamsRouter);
app.use(`${env.API_PREFIX}/admin`, questionsRouter);
app.use(`${env.API_PREFIX}/admin/exams`, adminResultsRouter);
app.use(`${env.API_PREFIX}/admin`, adminSessionsRouter);
app.use(`${env.API_PREFIX}/admin/monitoring`, monitoringRouter);
app.use(`${env.API_PREFIX}/admin/uploads`, uploadsRouter);

app.use((_req, _res, next) => {
  next(new AppError("Route not found", 404, "ROUTE_NOT_FOUND"));
});

app.use(errorHandler);

server.listen(env.PORT, () => {
  logger.info(`${env.APP_NAME} listening on port ${env.PORT}`);
});
