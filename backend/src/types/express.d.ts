import type { AdminRole } from "@prisma/client";

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        subjectType: "student" | "admin";
        role?: AdminRole;
      };
    }
  }
}

export {};

