import { Router } from "express";

import { asyncHandler } from "../../middlewares/asyncHandler.js";
import { authenticate } from "../../middlewares/auth.js";
import { validateBody } from "../../middlewares/validate.js";
import { AnswersController } from "./answers.controller.js";
import { saveAnswerSchema, syncAnswersSchema } from "./answers.schema.js";

const controller = new AnswersController();

export const answersRouter = Router();
answersRouter.use(authenticate);
answersRouter.post("/", validateBody(saveAnswerSchema), asyncHandler(controller.save));
answersRouter.post("/sync", validateBody(syncAnswersSchema), asyncHandler(controller.sync));

