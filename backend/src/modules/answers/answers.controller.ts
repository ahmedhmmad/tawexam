import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AnswersService } from "./answers.service.js";

const answersService = new AnswersService();

export class AnswersController {
  async save(req: Request, res: Response): Promise<Response> {
    const studentId = req.user?.id;
    const result = await answersService.saveAnswer(req.body, studentId);
    return sendSuccess(res, result, "Answer saved");
  }

  async sync(req: Request, res: Response): Promise<Response> {
    const studentId = req.user?.id;
    const result = await answersService.syncAnswers(req.body.answers, studentId);
    return sendSuccess(res, result, "Answers synced");
  }
}

