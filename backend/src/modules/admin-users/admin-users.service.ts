import { AdminRole } from "@prisma/client";

import { AppError } from "../../utils/app-error.js";
import { hashPassword } from "../../utils/password.js";
import { AdminUsersRepository } from "./admin-users.repository.js";

interface CreateInput {
  username: string;
  password: string;
  role: AdminRole;
  isActive?: boolean;
}

interface UpdateInput {
  username?: string;
  role?: AdminRole;
  isActive?: boolean;
}

export class AdminUsersService {
  constructor(private readonly repository: AdminUsersRepository = new AdminUsersRepository()) {}

  list() {
    return this.repository.list();
  }

  async create(input: CreateInput) {
    const existing = await this.repository.findByUsername(input.username);
    if (existing) {
      throw new AppError("Username already exists", 409, "USERNAME_TAKEN");
    }
    const passwordHash = await hashPassword(input.password);
    return this.repository.create({
      username: input.username,
      passwordHash,
      role: input.role,
      isActive: input.isActive ?? true
    });
  }

  async update(id: string, actingAdminId: string, input: UpdateInput) {
    const target = await this.requireUser(id);

    // Renaming to a username someone else already has is a conflict.
    if (input.username && input.username !== target.username) {
      const clash = await this.repository.findByUsername(input.username);
      if (clash) throw new AppError("Username already exists", 409, "USERNAME_TAKEN");
    }

    // Guard against locking everyone out: the last active super admin can't be
    // demoted or deactivated, and admins can't deactivate themselves.
    const losingSuperAdmin =
      target.role === AdminRole.SUPER_ADMIN &&
      ((input.role !== undefined && input.role !== AdminRole.SUPER_ADMIN) || input.isActive === false);
    if (losingSuperAdmin) {
      const others = await this.repository.countOtherActiveSuperAdmins(id);
      if (others === 0) {
        throw new AppError("Cannot remove the last active super admin", 400, "LAST_SUPER_ADMIN");
      }
    }
    if (id === actingAdminId && input.isActive === false) {
      throw new AppError("You cannot deactivate your own account", 400, "SELF_DEACTIVATION");
    }

    return this.repository.update(id, {
      username: input.username,
      role: input.role,
      isActive: input.isActive
    });
  }

  async resetPassword(id: string, password: string) {
    await this.requireUser(id);
    const passwordHash = await hashPassword(password);
    await this.repository.update(id, { passwordHash });
    return { reset: true };
  }

  async delete(id: string, actingAdminId: string) {
    const target = await this.requireUser(id);
    if (id === actingAdminId) {
      throw new AppError("You cannot delete your own account", 400, "SELF_DELETION");
    }
    if (target.role === AdminRole.SUPER_ADMIN && target.isActive) {
      const others = await this.repository.countOtherActiveSuperAdmins(id);
      if (others === 0) {
        throw new AppError("Cannot delete the last active super admin", 400, "LAST_SUPER_ADMIN");
      }
    }
    await this.repository.delete(id);
    return { deleted: true };
  }

  private async requireUser(id: string) {
    const user = await this.repository.findById(id);
    if (!user) throw new AppError("Admin user not found", 404, "ADMIN_USER_NOT_FOUND");
    return user;
  }
}
