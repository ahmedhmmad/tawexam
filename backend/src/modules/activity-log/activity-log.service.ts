import { AdminRole } from "@prisma/client";

import { prisma } from "../../config/prisma.js";
import { logger } from "../../config/logger.js";
import { monitoringService } from "../monitoring/monitoring.controller.js";
import { ActivityLogRepository, type ActivityFilter } from "./activity-log.repository.js";

export interface RecordParams {
  eventType: string;
  studentId?: string | null;
  userId?: string | null;
  examId?: string | null;
  description?: string | null;
  metadata?: unknown;
  ipAddress?: string | null;
  deviceIdentifier?: string | null;
}

export class ActivityLogService {
  constructor(private readonly repository: ActivityLogRepository = new ActivityLogRepository()) {}

  /**
   * Fire-and-forget event recording. NEVER throws and never blocks the caller —
   * a logging failure must not affect the exam flow. Also pushes the event to
   * the live monitoring feed over Socket.IO.
   */
  record(params: RecordParams): void {
    void this.repository
      .create(params)
      .then((row) => {
        try {
          monitoringService.emitEvent("activity:new", {
            id: row.id,
            eventType: row.eventType,
            studentId: row.studentId,
            examId: row.examId,
            description: row.description,
            createdAt: row.createdAt.toISOString()
          });
        } catch {
          // socket not ready — ignore
        }
      })
      .catch((error) => {
        logger.warn("ActivityLog record failed", { eventType: params.eventType, error });
      });
  }

  async query(filter: ActivityFilter, page: number, limit: number) {
    const result = await this.repository.query(filter, page, limit);
    return { ...result, rows: await this.enrich(result.rows) };
  }

  async listForExport(filter: ActivityFilter) {
    return this.enrich(await this.repository.listForExport(filter));
  }

  /**
   * Activity rows store only ids (no FK joins). Attach human-readable student
   * name / seat number and exam name via a single batched lookup each.
   */
  private async enrich<T extends { studentId: string | null; examId: string | null }>(
    rows: T[]
  ): Promise<Array<T & { studentName: string | null; seatNumber: string | null; examName: string | null }>> {
    const studentIds = [...new Set(rows.map((r) => r.studentId).filter((v): v is string => !!v))];
    const examIds = [...new Set(rows.map((r) => r.examId).filter((v): v is string => !!v))];

    const [students, exams] = await Promise.all([
      studentIds.length
        ? prisma.student.findMany({
            where: { id: { in: studentIds } },
            select: { id: true, fullName: true, seatNumber: true }
          })
        : Promise.resolve([]),
      examIds.length
        ? prisma.exam.findMany({
            where: { id: { in: examIds } },
            select: { id: true, subjectNameAr: true }
          })
        : Promise.resolve([])
    ]);

    const studentMap = new Map(students.map((s) => [s.id, s]));
    const examMap = new Map(exams.map((e) => [e.id, e]));

    return rows.map((r) => ({
      ...r,
      studentName: r.studentId ? studentMap.get(r.studentId)?.fullName ?? null : null,
      seatNumber: r.studentId ? studentMap.get(r.studentId)?.seatNumber ?? null : null,
      examName: r.examId ? examMap.get(r.examId)?.subjectNameAr ?? null : null
    }));
  }

  deleteMany(filter: ActivityFilter) {
    return this.repository.deleteMany(filter);
  }

  /** Exam ids created by a given teacher — used to scope their log access. */
  async examIdsForTeacher(teacherId: string): Promise<string[]> {
    const exams = await prisma.exam.findMany({
      where: { createdById: teacherId },
      select: { id: true }
    });
    return exams.map((e) => e.id);
  }

  /**
   * Apply role-based scoping to a requested filter. SUPER_ADMIN/ADMIN/SUPERVISOR
   * see everything; TEACHER is restricted to exams they created.
   */
  async scopeFilter(
    filter: ActivityFilter,
    user: { id: string; role?: AdminRole }
  ): Promise<ActivityFilter> {
    if (user.role !== AdminRole.TEACHER) return filter;
    const ownExamIds = await this.examIdsForTeacher(user.id);
    // Intersect any requested examId with the teacher's own exams.
    if (filter.examId) {
      return ownExamIds.includes(filter.examId)
        ? filter
        : { ...filter, examIds: ["__none__"], examId: undefined };
    }
    return { ...filter, examIds: ownExamIds.length > 0 ? ownExamIds : ["__none__"] };
  }
}

export const activityLogService = new ActivityLogService();
