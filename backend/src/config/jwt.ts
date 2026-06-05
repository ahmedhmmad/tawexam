import jwt, { type SignOptions } from "jsonwebtoken";

import { env } from "./env.js";

export interface JwtPayloadBase {
  sub: string;
  subjectType: "student" | "admin";
  role?: string;
  jti?: string;
}

function commonOptions(expiresIn: string): SignOptions {
  return {
    algorithm: "RS256",
    expiresIn: expiresIn as SignOptions["expiresIn"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  };
}

export function signAccessToken(payload: JwtPayloadBase): string {
  return jwt.sign(payload, env.JWT_ACCESS_PRIVATE_KEY, commonOptions(env.JWT_ACCESS_EXPIRES_IN));
}

export function signRefreshToken(payload: JwtPayloadBase): string {
  return jwt.sign(payload, env.JWT_REFRESH_PRIVATE_KEY, commonOptions(env.JWT_REFRESH_EXPIRES_IN));
}

export function verifyAccessToken(token: string): JwtPayloadBase {
  return jwt.verify(token, env.JWT_ACCESS_PUBLIC_KEY, {
    algorithms: ["RS256"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  }) as JwtPayloadBase;
}

export function verifyRefreshToken(token: string): JwtPayloadBase {
  return jwt.verify(token, env.JWT_REFRESH_PUBLIC_KEY, {
    algorithms: ["RS256"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  }) as JwtPayloadBase;
}
