import type { Prisma } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

export interface ActivityFilter {
  examId?: string;
  studentId?: string;
  eventType?: string;
  from?: Date;
  to?: Date;
  /** When set, restrict to these exam ids (teacher scoping). */
  examIds?: string[];
}

function buildWhere(filter: ActivityFilter): Prisma.ActivityLogWhereInput {
  const where: Prisma.ActivityLogWhereInput = {};
  if (filter.examId) where.examId = filter.examId;
  if (filter.studentId) where.studentId = filter.studentId;
  if (filter.eventType) where.eventType = filter.eventType;
  if (filter.examIds) where.examId = { in: filter.examIds };
  if (filter.from || filter.to) {
    where.createdAt = {};
    if (filter.from) where.createdAt.gte = filter.from;
    if (filter.to) where.createdAt.lte = filter.to;
  }
  return where;
}

export class ActivityLogRepository {
  create(data: {
    userId?: string | null;
    studentId?: string | null;
    examId?: string | null;
    eventType: string;
    description?: string | null;
    metadata?: unknown;
    ipAddress?: string | null;
    deviceIdentifier?: string | null;
  }) {
    return prisma.activityLog.create({
      data: {
        userId: data.userId ?? null,
        studentId: data.studentId ?? null,
        examId: data.examId ?? null,
        eventType: data.eventType,
        description: data.description ?? null,
        metadata: (data.metadata ?? {}) as Prisma.InputJsonValue,
        ipAddress: data.ipAddress ?? null,
        deviceIdentifier: data.deviceIdentifier ?? null
      }
    });
  }

  async query(filter: ActivityFilter, page: number, limit: number) {
    const where = buildWhere(filter);
    const [rows, total] = await Promise.all([
      prisma.activityLog.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit
      }),
      prisma.activityLog.count({ where })
    ]);
    return { rows, total, page, limit };
  }

  listForExport(filter: ActivityFilter, cap = 5000) {
    return prisma.activityLog.findMany({
      where: buildWhere(filter),
      orderBy: { createdAt: "desc" },
      take: cap
    });
  }

  deleteMany(filter: ActivityFilter) {
    return prisma.activityLog.deleteMany({ where: buildWhere(filter) });
  }
}
