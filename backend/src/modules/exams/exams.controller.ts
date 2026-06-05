import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AuditLogService } from "../../utils/audit-log.service.js";
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
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "CREATE",
      targetEntity: "Exam",
      targetId: exam.id,
      payload: req.body
    });
    return sendSuccess(res, exam, "Exam created", 201);
  }

  async update(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.update(req.params.id as string, req.body);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "UPDATE",
      targetEntity: "Exam",
      targetId: req.params.id as string,
      payload: req.body
    });
    return sendSuccess(res, exam, "Exam updated");
  }

  async remove(req: Request, res: Response): Promise<Response> {
    await examsService.delete(req.params.id as string);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "DELETE",
      targetEntity: "Exam",
      targetId: req.params.id as string
    });
    return sendSuccess(res, { deleted: true }, "Exam deleted");
  }

  async duplicate(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.duplicate(req.params.id as string, req.user!.id);
    if (!exam) {
      return sendSuccess(res, null, "Exam not found", 404);
    }
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "DUPLICATE",
      targetEntity: "Exam",
      targetId: exam.id,
      payload: { sourceId: req.params.id }
    });
    return sendSuccess(res, exam, "Exam duplicated", 201);
  }

  async updateStatus(req: Request, res: Response): Promise<Response> {
    const exam = await examsService.updateStatus(req.params.id as string, req.body.status);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "UPDATE_STATUS",
      targetEntity: "Exam",
      targetId: req.params.id as string,
      payload: { status: req.body.status }
    });
    return sendSuccess(res, exam, "Exam status updated");
  }
}
