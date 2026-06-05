import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export class AuditLogService {
  static async log(params: {
    adminId: string;
    action: string;
    targetEntity: string;
    targetId: string;
    payload?: unknown;
  }): Promise<void> {
    await prisma.auditLog.create({
      data: {
        adminId: params.adminId,
        action: params.action,
        targetEntity: params.targetEntity,
        targetId: params.targetId,
        payload: (params.payload ?? {}) as object
      }
    });
  }
}
