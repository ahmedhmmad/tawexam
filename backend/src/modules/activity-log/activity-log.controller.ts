import type { Request, Response } from "express";
import xlsx from "xlsx";

import { sendSuccess } from "../../utils/api-response.js";
import { AuditLogService } from "../../utils/audit-log.service.js";
import type { ActivityFilter } from "./activity-log.repository.js";
import { activityLogService } from "./activity-log.service.js";

function clientIp(req: Request): string | undefined {
  const fwd = req.headers["x-forwarded-for"];
  if (typeof fwd === "string" && fwd.length > 0) return fwd.split(",")[0]!.trim();
  return req.ip;
}

function filterFromQuery(q: Record<string, unknown>): ActivityFilter {
  return {
    examId: q.examId as string | undefined,
    studentId: q.studentId as string | undefined,
    eventType: q.eventType as string | undefined,
    from: q.from as Date | undefined,
    to: q.to as Date | undefined
  };
}

export class ActivityLogController {
  /** Student self-reports a client-side event (studentId from the token). */
  async report(req: Request, res: Response): Promise<Response> {
    activityLogService.record({
      eventType: req.body.eventType,
      studentId: req.user!.id,
      examId: req.body.examId ?? null,
      description: req.body.description ?? null,
      metadata: req.body.metadata,
      ipAddress: clientIp(req),
      deviceIdentifier: req.body.deviceIdentifier ?? null
    });
    return sendSuccess(res, { accepted: true }, "Event recorded", 202);
  }

  async list(req: Request, res: Response): Promise<Response> {
    const q = req.query as Record<string, unknown>;
    const filter = await activityLogService.scopeFilter(filterFromQuery(q), req.user!);
    const page = Number(q.page ?? 1);
    const limit = Number(q.limit ?? 50);
    const result = await activityLogService.query(filter, page, limit);

    // Rule: all log ACCESS is itself audit logged.
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "VIEW_ACTIVITY_LOG",
      targetEntity: "ActivityLog",
      targetId: filter.examId ?? filter.studentId ?? "all",
      payload: { examId: q.examId, studentId: q.studentId, eventType: q.eventType }
    });
    return sendSuccess(res, result);
  }

  async export(req: Request, res: Response): Promise<Response> {
    const q = req.query as Record<string, unknown>;
    const filter = await activityLogService.scopeFilter(filterFromQuery(q), req.user!);
    const rows = await activityLogService.listForExport(filter);

    await AuditLogService.log({
      adminId: req.user!.id,
      action: "EXPORT_ACTIVITY_LOG",
      targetEntity: "ActivityLog",
      targetId: filter.examId ?? "all",
      payload: { count: rows.length }
    });

    const sheet = xlsx.utils.json_to_sheet(
      rows.map((r) => ({
        createdAt: r.createdAt.toISOString(),
        eventType: r.eventType,
        studentName: r.studentName,
        seatNumber: r.seatNumber,
        examName: r.examName,
        studentId: r.studentId,
        examId: r.examId,
        description: r.description,
        ipAddress: r.ipAddress,
        deviceIdentifier: r.deviceIdentifier,
        metadata: JSON.stringify(r.metadata)
      }))
    );
    const workbook = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(workbook, sheet, "Activity");
    const buffer = xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
    res.setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    res.setHeader("Content-Disposition", 'attachment; filename="activity-log.xlsx"');
    return res.status(200).send(buffer);
  }

  /** SUPER_ADMIN-only: delete logs matching a filter (error recovery / cleanup). */
  async remove(req: Request, res: Response): Promise<Response> {
    const filter = filterFromQuery(req.query as Record<string, unknown>);
    const result = await activityLogService.deleteMany(filter);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "DELETE_ACTIVITY_LOG",
      targetEntity: "ActivityLog",
      targetId: filter.examId ?? filter.studentId ?? "all",
      payload: { deleted: result.count, filter: req.query }
    });
    return sendSuccess(res, { deleted: result.count }, "Activity logs deleted");
  }
}
