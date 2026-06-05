import { prisma } from "../../config/prisma.js";

export class AuthRepository {
  findStudentBySeatNumber(seatNumber: string) {
    return prisma.student.findUnique({ where: { seatNumber } });
  }

  findStudentById(id: string) {
    return prisma.student.findUnique({ where: { id } });
  }

  findAdminByUsername(username: string) {
    return prisma.adminUser.findUnique({ where: { username } });
  }

  findAdminById(id: string) {
    return prisma.adminUser.findUnique({ where: { id } });
  }
}
