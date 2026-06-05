import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { StudentsService } from "./students.service.js";

const studentsService = new StudentsService();

export class StudentsController {
  async list(req: Request, res: Response): Promise<Response> {
    const result = await studentsService.list(req.query as never);
    return sendSuccess(res, result);
  }

  async create(req: Request, res: Response): Promise<Response> {
    const student = await studentsService.create(req.body);
    return sendSuccess(res, student, "Student created", 201);
  }

  async update(req: Request, res: Response): Promise<Response> {
    const student = await studentsService.update(req.params.id as string, req.body);
    return sendSuccess(res, student, "Student updated");
  }

  async remove(req: Request, res: Response): Promise<Response> {
    await studentsService.delete(req.params.id as string);
    return sendSuccess(res, { deleted: true }, "Student deleted");
  }

  async import(req: Request, res: Response): Promise<Response> {
    const result = await studentsService.importFromWorkbook(req.file as Express.Multer.File);
    return sendSuccess(res, result, "Students imported");
  }

  async export(_req: Request, res: Response): Promise<Response> {
    const buffer = await studentsService.exportWorkbook();
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", 'attachment; filename="students.xlsx"');
    return res.status(200).send(buffer);
  }

  async resetPassword(req: Request, res: Response): Promise<Response> {
    const result = await studentsService.resetPassword(req.params.id as string, req.body.password);
    return sendSuccess(res, result, "Password reset");
  }
}
