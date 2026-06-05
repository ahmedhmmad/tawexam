import type { Request, Response } from "express";

import { sendSuccess } from "../../utils/api-response.js";
import { AuthService } from "./auth.service.js";

const authService = new AuthService();

export class AuthController {
  async studentLogin(req: Request, res: Response): Promise<Response> {
    const result = await authService.loginStudent(req.body.seatNumber, req.body.password);
    return sendSuccess(res, result, "Login successful");
  }

  async adminLogin(req: Request, res: Response): Promise<Response> {
    const result = await authService.loginAdmin(req.body.username, req.body.password);
    return sendSuccess(res, result, "Login successful");
  }

  async refresh(req: Request, res: Response): Promise<Response> {
    const result = await authService.refresh(req.body.refreshToken);
    return sendSuccess(res, result, "Token refreshed");
  }

  async logout(req: Request, res: Response): Promise<Response> {
    await authService.logout(req.body.refreshToken);
    return sendSuccess(res, { loggedOut: true }, "Logged out");
  }
}

