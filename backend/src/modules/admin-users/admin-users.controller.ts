import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AuditLogService } from "../../utils/audit-log.service.js";
import { AdminUsersService } from "./admin-users.service.js";

const adminUsersService = new AdminUsersService();

export class AdminUsersController {
  async list(_req: Request, res: Response): Promise<Response> {
    const users = await adminUsersService.list();
    return sendSuccess(res, users);
  }

  async create(req: Request, res: Response): Promise<Response> {
    const user = await adminUsersService.create(req.body);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "CREATE",
      targetEntity: "AdminUser",
      targetId: user.id,
      payload: { username: user.username, role: user.role }
    });
    return sendSuccess(res, user, "Admin user created", 201);
  }

  async update(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const user = await adminUsersService.update(id, req.user!.id, req.body);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "UPDATE",
      targetEntity: "AdminUser",
      targetId: id,
      payload: req.body
    });
    return sendSuccess(res, user, "Admin user updated");
  }

  async resetPassword(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const result = await adminUsersService.resetPassword(id, req.body.password);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "RESET_PASSWORD",
      targetEntity: "AdminUser",
      targetId: id
    });
    return sendSuccess(res, result, "Password reset");
  }

  async remove(req: Request, res: Response): Promise<Response> {
    const id = req.params.id as string;
    const result = await adminUsersService.delete(id, req.user!.id);
    await AuditLogService.log({
      adminId: req.user!.id,
      action: "DELETE",
      targetEntity: "AdminUser",
      targetId: id
    });
    return sendSuccess(res, result, "Admin user deleted");
  }
}
