import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { ExamsService } from "./exams.service.js";

const examsService = new ExamsService();

export class ExamsController {
  async current(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.currentForStudent(req.user!.id);
    return sendSuccess(res, exam);
  }

  async studentQuestions(req: Request, res: Response): Promise<Response> {
    const questions = await examsService.studentQuestions(req.params.id as string, req.user!.id);
    return sendSuccess(res, questions);
  }

  async submit(req: Request, res: Response): Promise<Response> {
    const result = await examsService.submitExam(req.params.id as string, req.user!.id);
    return sendSuccess(res, result, "Exam submitted");
  }

  async list(_req: Request, res: Response): Promise<Response> {
    const exams = await examsService.list();
    return sendSuccess(res, exams);
  }

  async create(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.create({ ...req.body, createdById: req.user!.id });
    return sendSuccess(res, exam, "Exam created", 201);
  }

  async update(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.update(req.params.id as string, req.body);
    return sendSuccess(res, exam, "Exam updated");
  }

  async remove(req: Request, res: Response): Promise<Response> {
    await examsService.delete(req.params.id as string);
    return sendSuccess(res, { deleted: true }, "Exam deleted");
  }

  async duplicate(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.duplicate(req.params.id as string, req.user!.id);
    return sendSuccess(res, exam, "Exam duplicated", 201);
  }

  async updateStatus(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.updateStatus(req.params.id as string, req.body.status);
    return sendSuccess(res, exam, "Exam status updated");
  }
}
