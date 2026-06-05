import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { QuestionsService } from "./questions.service.js";

const questionsService = new QuestionsService();

export class QuestionsController {
  async list(req: Request, res: Response): Promise<Response> {
    const questions = await questionsService.listByExam(req.params.id);
    return sendSuccess(res, questions);
  }

  async create(req: Request, res: Response): Promise<Response> {
    const question = await questionsService.create(req.params.id, req.body);
    return sendSuccess(res, question, "Question created", 201);
  }

  async update(req: Request, res: Response): Promise<Response> {
    const question = await questionsService.update(req.params.id, req.body);
    return sendSuccess(res, question, "Question updated");
  }

  async remove(req: Request, res: Response): Promise<Response> {
    await questionsService.delete(req.params.id);
    return sendSuccess(res, { deleted: true }, "Question deleted");
  }

  async validateImport(req: Request, res: Response): Promise<Response> {
    const result = questionsService.validateWorkbook(req.file as Express.Multer.File);
    return sendSuccess(res, result, "Workbook validated");
  }

  async importQuestions(req: Request, res: Response): Promise<Response> {
    const result = await questionsService.importWorkbook(
      req.params.id,
      req.file as Express.Multer.File,
      req.body.mode ?? "append"
    );
    return sendSuccess(res, result, "Questions imported");
  }

  template(_req: Request, res: Response): Response {
    const buffer = questionsService.templateWorkbook();
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", 'attachment; filename="question-template.xlsx"');
    return res.status(200).send(buffer);
  }
}

