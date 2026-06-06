import type { AdminRole } from "@prisma/client";

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    subjectType: "student" | "admin";
    role?: AdminRole;
    username?: string;
    seatNumber?: string;
    fullName?: string;
    branch?: string;
  };
}

