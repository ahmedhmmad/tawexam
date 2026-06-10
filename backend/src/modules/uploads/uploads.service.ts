import { randomUUID } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";

import sharp from "sharp";

import { env } from "../../config/env.js";
import { logger } from "../../config/logger.js";
import { AppError } from "../../utils/app-error.js";

export const ALLOWED_IMAGE_MIME_TYPES = [
  "image/png",
  "image/jpeg",
  "image/webp"
];

export const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

// Output cap: large originals are downscaled to keep mobile payloads small.
const MAX_DIMENSION = 1280;
const WEBP_QUALITY = 80;

const QUESTIONS_URL_PREFIX = "/uploads/questions/";

export class UploadsService {
  constructor(private readonly uploadDir: string = env.UPLOAD_DIR) {}

  private get questionsDir(): string {
    return path.join(this.uploadDir, "questions");
  }

  async saveQuestionImage(file: Express.Multer.File | undefined): Promise<{ url: string }> {
    if (!file || !file.buffer || file.buffer.length === 0) {
      throw new AppError("No image file provided", 400, "NO_FILE");
    }
    if (!ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new AppError(
        "Unsupported image type. Allowed: PNG, JPG, JPEG, WEBP",
        400,
        "INVALID_IMAGE_TYPE"
      );
    }
    if (file.buffer.length > MAX_IMAGE_BYTES) {
      throw new AppError("Image exceeds the 2MB size limit", 400, "FILE_TOO_LARGE");
    }

    // sharp re-encodes from pixel data, so a malicious payload with a spoofed
    // image MIME type fails here instead of being persisted verbatim.
    let output: Buffer;
    try {
      output = await sharp(file.buffer)
        .rotate()
        .resize(MAX_DIMENSION, MAX_DIMENSION, { fit: "inside", withoutEnlargement: true })
        .webp({ quality: WEBP_QUALITY })
        .toBuffer();
    } catch {
      throw new AppError("Invalid or corrupted image file", 400, "INVALID_IMAGE");
    }

    await fs.mkdir(this.questionsDir, { recursive: true });
    const filename = `${randomUUID()}.webp`;
    await fs.writeFile(path.join(this.questionsDir, filename), output);

    return { url: `${QUESTIONS_URL_PREFIX}${filename}` };
  }

  /** Best-effort removal of stored question/choice images; never throws. */
  async deleteQuestionImages(urls: Array<string | null | undefined>): Promise<void> {
    for (const url of urls) {
      if (!url || !url.startsWith(QUESTIONS_URL_PREFIX)) continue;
      const filename = path.basename(url);
      // basename strips any traversal segments; only delete inside questionsDir
      try {
        await fs.unlink(path.join(this.questionsDir, filename));
      } catch (error) {
        logger.warn("Failed to delete question image", { url, error });
      }
    }
  }
}

export const uploadsService = new UploadsService();
