import { AdminRole, type Prisma } from "@prisma/client";

import { prisma } from "../../config/prisma.js";

// Never expose passwordHash to the API.
const publicSelect = {
  id: true,
  username: true,
  role: true,
  isActive: true,
  createdAt: true
} satisfies Prisma.AdminUserSelect;

export class AdminUsersRepository {
  list() {
    return prisma.adminUser.findMany({
      select: publicSelect,
      orderBy: { createdAt: "asc" }
    });
  }

  findById(id: string) {
    return prisma.adminUser.findUnique({ where: { id } });
  }

  findByUsername(username: string) {
    return prisma.adminUser.findUnique({ where: { username } });
  }

  create(data: { username: string; passwordHash: string; role: AdminRole; isActive: boolean }) {
    return prisma.adminUser.create({ data, select: publicSelect });
  }

  update(id: string, data: Prisma.AdminUserUpdateInput) {
    return prisma.adminUser.update({ where: { id }, data, select: publicSelect });
  }

  delete(id: string) {
    return prisma.adminUser.delete({ where: { id } });
  }

  /** Count of OTHER active super admins (excludes the given id). */
  countOtherActiveSuperAdmins(excludeId: string) {
    return prisma.adminUser.count({
      where: { role: AdminRole.SUPER_ADMIN, isActive: true, id: { not: excludeId } }
    });
  }
}
