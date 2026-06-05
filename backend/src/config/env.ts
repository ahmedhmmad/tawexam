import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  APP_NAME: z.string().default("tawjihi-platform"),
  API_PREFIX: z.string().default("/api/v1"),
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().min(1),
  JWT_ACCESS_PRIVATE_KEY: z.string().min(1),
  JWT_ACCESS_PUBLIC_KEY: z.string().min(1),
  JWT_REFRESH_PRIVATE_KEY: z.string().min(1),
  JWT_REFRESH_PUBLIC_KEY: z.string().min(1),
  JWT_ACCESS_EXPIRES_IN: z.string().default("15m"),
  JWT_REFRESH_EXPIRES_IN: z.string().default("7d"),
  JWT_ISSUER: z.string().default("tawjihi-platform"),
  JWT_AUDIENCE: z.string().default("tawjihi-platform-users"),
  CORS_ORIGIN: z.string().default("*"),
  UPLOAD_DIR: z.string().default("/app/uploads"),
  LOG_LEVEL: z.string().default("info"),
  DOMAIN: z.string().default("your-domain.com"),
  CERTBOT_EMAIL: z.string().email().or(z.literal("admin@your-domain.com"))
});

export const env = envSchema.parse(process.env);

