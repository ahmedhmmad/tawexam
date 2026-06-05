import type { Prisma, Student } from "@prisma/client";

import { prisma } from "../../config/prisma.js";
import type { StudentFilters } from "./students.types.js";

export class StudentsRepository {
  async list(filters: StudentFilters): Promise<{ data: Student[]; total: number }> {
    const where: Prisma.StudentWhereInput = {
      branch: filters.branch,
      isActive: filters.isActive,
      OR: filters.search
        ? [
            { fullName: { contains: filters.search, mode: "insensitive" } },
            { seatNumber: { contains: filters.search, mode: "insensitive" } }
          ]
        : undefined
    };

    const [data, total] = await prisma.$transaction([
      prisma.student.findMany({
        where,
        skip: (filters.page - 1) * filters.limit,
        take: filters.limit,
        orderBy: { createdAt: "desc" }
      }),
      prisma.student.count({ where })
    ]);

    return { data, total };
  }

  create(data: Prisma.StudentCreateInput) {
    return prisma.student.create({ data });
  }

  update(id: string, data: Prisma.StudentUpdateInput) {
    return prisma.student.update({ where: { id }, data });
  }

  delete(id: string) {
    return prisma.student.delete({ where: { id } });
  }

  findById(id: string) {
    return prisma.student.findUnique({ where: { id } });
  }

  async upsertMany(
    rows: Array<{
      seatNumber: string;
      fullName: string;
      passwordHash: string;
      mobileNo: string;
      branch: string;
      schoolName: string;
      isActive: boolean;
    }>
  ): Promise<number> {
    await prisma.$transaction(
      rows.map((row) =>
        prisma.student.upsert({
          where: { seatNumber: row.seatNumber },
          update: { fullName: row.fullName, passwordHash: row.passwordHash, mobileNo: row.mobileNo, branch: row.branch, isActive: row.isActive },
          create: row
        })
      )
    );
    return rows.length;
  }

  exportAll() {
    return prisma.student.findMany({ orderBy: { fullName: "asc" } });
  }
}

