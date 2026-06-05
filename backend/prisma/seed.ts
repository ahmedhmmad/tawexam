import bcrypt from "bcrypt";
import { PrismaClient, AdminRole } from "@prisma/client";

const prisma = new PrismaClient();

async function main(): Promise<void> {
  const username = process.env.ADMIN_USERNAME ?? "superadmin";
  const password = process.env.ADMIN_PASSWORD ?? "ChangeMe123!";
  const passwordHash = await bcrypt.hash(password, 12);

  await prisma.adminUser.upsert({
    where: { username },
    update: { passwordHash, role: AdminRole.SUPER_ADMIN, isActive: true },
    create: {
      username,
      passwordHash,
      role: AdminRole.SUPER_ADMIN,
      isActive: true
    }
  });
}

main()
  .catch(async (error) => {
    console.error(error);
    process.exitCode = 1;
    await prisma.$disconnect();
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

