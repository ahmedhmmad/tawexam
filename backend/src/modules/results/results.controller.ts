import type { Request, Response } from "express";

import { prisma } from "../../config/prisma.js";
import { AppError } from "../../utils/app-error.js";
import { sendSuccess } from "../../utils/api-response.js";
import { ResultsService } from "./results.service.js";

const resultsService = new ResultsService();

export class ResultsController {
  async studentResult(req: Request, res: Response): Promise<Response> {
    const examId = req.params.id as string;

    // Check if admin has enabled result viewing
    const exam = await prisma.exam.findUnique({ where: { id: examId }, select: { showResults: true, showAnswers: true } });
    if (!exam) {
      throw new AppError("Exam not found", 404, "EXAM_NOT_FOUND");
    }

    if (!exam.showResults) {
      return sendSuccess(res, {
        visible: false,
        message: "سيتم عرض النتائج لاحقاً بقرار من المشرف"
      });
    }

    const result = await resultsService.getStudentResult(examId, req.user!.id);

    // If showAnswers is false, strip correct answers from response
    if (!exam.showAnswers) {
      return sendSuccess(res, {
        visible: true,
        showAnswers: false,
        score: result.score,
        totalQuestions: result.totalQuestions,
        correctCount: result.correctCount,
        answeredCount: result.answeredCount,
        timeTakenSeconds: result.timeTakenSeconds
      });
    }

    return sendSuccess(res, { visible: true, showAnswers: true, ...result });
  }

  async analytics(req: Request, res: Response): Promise<Response> {
    const result = await resultsService.analytics(req.params.id as string);
    return sendSuccess(res, result);
  }

  async list(req: Request, res: Response): Promise<Response> {
    const results = await resultsService.listResults(req.params.id as string);
    return sendSuccess(res, results);
  }

  async export(req: Request, res: Response): Promise<Response> {
    const buffer = await resultsService.exportExamResults(req.params.id as string);
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", 'attachment; filename="exam-results.xlsx"');
    return res.status(200).send(buffer);
  }
}
