import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { ResultsService } from "./results.service.js";

const resultsService = new ResultsService();

export class ResultsController {
  async studentResult(req: Request, res: Response): Promise<Response> {
    const result = await resultsService.getStudentResult(req.params.id as string, req.user!.id);
    return sendSuccess(res, result);
  }

  async analytics(req: Request, res: Response): Promise<Response> {
    const result = await resultsService.analytics(req.params.id as string);
    return sendSuccess(res, result);
  }

  async export(req: Request, res: Response): Promise<Response> {
    const buffer = await resultsService.exportExamResults(req.params.id as string);
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", 'attachment; filename="exam-results.xlsx"');
    return res.status(200).send(buffer);
  }
}
