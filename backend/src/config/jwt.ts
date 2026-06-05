import jwt, { type SignOptions } from "jsonwebtoken";

import { env } from "./env.js";

export interface JwtPayloadBase {
  sub: string;
  subjectType: "student" | "admin";
  role?: string;
  jti?: string;
}

// Fix escaped newlines from .env files (Docker Compose passes literal \n)
function fixKey(key: string): string {
  return key.replace(/\\n/g, "\n");
}

const accessPrivateKey = fixKey(env.JWT_ACCESS_PRIVATE_KEY);
const accessPublicKey = fixKey(env.JWT_ACCESS_PUBLIC_KEY);
const refreshPrivateKey = fixKey(env.JWT_REFRESH_PRIVATE_KEY);
const refreshPublicKey = fixKey(env.JWT_REFRESH_PUBLIC_KEY);

function commonOptions(expiresIn: string): SignOptions {
  return {
    algorithm: "RS256",
    expiresIn: expiresIn as SignOptions["expiresIn"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  };
}

export function signAccessToken(payload: JwtPayloadBase): string {
  return jwt.sign(payload, accessPrivateKey, commonOptions(env.JWT_ACCESS_EXPIRES_IN));
}

export function signRefreshToken(payload: JwtPayloadBase): string {
  return jwt.sign(payload, refreshPrivateKey, commonOptions(env.JWT_REFRESH_EXPIRES_IN));
}

export function verifyAccessToken(token: string): JwtPayloadBase {
  return jwt.verify(token, accessPublicKey, {
    algorithms: ["RS256"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  }) as JwtPayloadBase;
}

export function verifyRefreshToken(token: string): JwtPayloadBase {
  return jwt.verify(token, refreshPublicKey, {
    algorithms: ["RS256"],
    issuer: env.JWT_ISSUER,
    audience: env.JWT_AUDIENCE
  }) as JwtPayloadBase;
}
