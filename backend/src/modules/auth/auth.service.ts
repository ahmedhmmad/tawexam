import { randomUUID } from "node:crypto";

import { comparePassword } from "../../utils/password.js";
import { AppError } from "../../utils/app-error.js";
import { redis } from "../../config/redis.js";
import {
  signAccessToken,
  signRefreshToken,
  verifyRefreshToken,
  type JwtPayloadBase
} from "../../config/jwt.js";
import type { LoginResult } from "./auth.types.js";
import { AuthRepository } from "./auth.repository.js";

export class AuthService {
  constructor(private readonly repository: AuthRepository = new AuthRepository()) {}

  async loginStudent(seatNumber: string, password: string): Promise<LoginResult> {
    const student = await this.repository.findStudentBySeatNumber(seatNumber);
    if (!student || !student.isActive) {
      throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
    }

    const valid = await comparePassword(password, student.passwordHash);
    if (!valid) {
      throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
    }

    return this.issueTokens({
      sub: student.id,
      subjectType: "student"
    }, {
      id: student.id,
      subjectType: "student",
      seatNumber: student.seatNumber,
      fullName: student.fullName
    });
  }

  async loginAdmin(username: string, password: string): Promise<LoginResult> {
    const admin = await this.repository.findAdminByUsername(username);
    if (!admin || !admin.isActive) {
      throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
    }

    const valid = await comparePassword(password, admin.passwordHash);
    if (!valid) {
      throw new AppError("Invalid credentials", 401, "INVALID_CREDENTIALS");
    }

    return this.issueTokens({
      sub: admin.id,
      subjectType: "admin",
      role: admin.role
    }, {
      id: admin.id,
      subjectType: "admin",
      username: admin.username,
      role: admin.role
    });
  }

  async refresh(refreshToken: string): Promise<LoginResult> {
    const payload = verifyRefreshToken(refreshToken);
    const stored = await redis.get(this.refreshKey(payload.jti ?? ""));
    if (stored !== refreshToken) {
      throw new AppError("Refresh token revoked", 401, "REFRESH_TOKEN_REVOKED");
    }

    await redis.del(this.refreshKey(payload.jti ?? ""));
    if (payload.subjectType === "admin") {
      const admin = await this.repository.findAdminById(payload.sub);
      if (!admin || !admin.isActive) {
        throw new AppError("Admin account unavailable", 401, "INVALID_ACCOUNT");
      }

      return this.issueTokens(
        { sub: admin.id, subjectType: "admin", role: admin.role },
        {
          id: admin.id,
          subjectType: "admin",
          username: admin.username,
          role: admin.role
        }
      );
    }

    const student = await this.repository.findStudentById(payload.sub);
    if (!student || !student.isActive) {
      throw new AppError("Student account unavailable", 401, "INVALID_ACCOUNT");
    }

    return this.issueTokens(
      { sub: student.id, subjectType: "student" },
      {
        id: student.id,
        subjectType: "student",
        seatNumber: student.seatNumber,
        fullName: student.fullName
      }
    );
  }

  async logout(refreshToken: string): Promise<void> {
    const payload = verifyRefreshToken(refreshToken);
    await redis.del(this.refreshKey(payload.jti ?? ""));
  }

  private async issueTokens(
    payload: JwtPayloadBase,
    user: LoginResult["user"]
  ): Promise<LoginResult> {
    const jti = randomUUID();
    const refreshToken = signRefreshToken({ ...payload, jti });
    const accessToken = signAccessToken(payload);
    await redis.set(this.refreshKey(jti), refreshToken, "EX", 7 * 24 * 60 * 60);
    return { accessToken, refreshToken, user };
  }

  private refreshKey(jti: string): string {
    return `refresh:${jti}`;
  }
}
