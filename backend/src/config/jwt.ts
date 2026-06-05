import { readFileSync } from "node:fs";
import jwt, { type SignOptions } from "jsonwebtoken";

import { env } from "./env.js";

export interface JwtPayloadBase {
  sub: string;
  subjectType: "student" | "admin";
  role?: string;
  jti?: string;
}

function loadKey(envValue: string): string {
  // If the env value is a file path (starts with /), read the file
  if (envValue.startsWith("/") && !envValue.includes("BEGIN")) {
    return readFileSync(envValue, "utf8");
  }
  // Otherwise treat as inline key with escaped newlines
  return envValue.replace(/\\n/g, "\n").replace(/§/g, "\n");
}

const accessPrivateKey = loadKey(env.JWT_ACCESS_PRIVATE_KEY);
const accessPublicKey = loadKey(env.JWT_ACCESS_PUBLIC_KEY);
const refreshPrivateKey = loadKey(env.JWT_REFRESH_PRIVATE_KEY);
const refreshPublicKey = loadKey(env.JWT_REFRESH_PUBLIC_KEY);

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
