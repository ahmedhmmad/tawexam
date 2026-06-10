import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import sharp from "sharp";

import { AppError } from "../../utils/app-error.js";
import { UploadsService } from "./uploads.service.js";

function fakeFile(overrides: Partial<Express.Multer.File>): Express.Multer.File {
  return {
    fieldname: "file",
    originalname: "test.png",
    encoding: "7bit",
    mimetype: "image/png",
    size: 0,
    buffer: Buffer.alloc(0),
    destination: "",
    filename: "",
    path: "",
    stream: undefined as never,
    ...overrides
  };
}

describe("UploadsService", () => {
  let tmpDir: string;
  let service: UploadsService;

  beforeAll(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), "taw-uploads-"));
    service = new UploadsService(tmpDir);
  });

  afterAll(async () => {
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  it("rejects a missing file", async () => {
    await expect(service.saveQuestionImage(undefined)).rejects.toMatchObject({
      code: "NO_FILE"
    });
  });

  it("rejects unsupported MIME types", async () => {
    const file = fakeFile({ mimetype: "image/gif", buffer: Buffer.from("GIF89a") });
    await expect(service.saveQuestionImage(file)).rejects.toMatchObject({
      code: "INVALID_IMAGE_TYPE"
    });
  });

  it("rejects files over the 2MB limit", async () => {
    const file = fakeFile({ buffer: Buffer.alloc(2 * 1024 * 1024 + 1) });
    await expect(service.saveQuestionImage(file)).rejects.toMatchObject({
      code: "FILE_TOO_LARGE"
    });
  });

  it("rejects a non-image payload with an image MIME type", async () => {
    const file = fakeFile({ buffer: Buffer.from("definitely not a png") });
    const error = await service.saveQuestionImage(file).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(AppError);
    expect((error as AppError).code).toBe("INVALID_IMAGE");
  });

  it("stores a valid PNG as WEBP and returns a relative URL", async () => {
    const png = await sharp({
      create: { width: 32, height: 16, channels: 3, background: { r: 200, g: 10, b: 10 } }
    }).png().toBuffer();
    const file = fakeFile({ buffer: png, size: png.length });

    const result = await service.saveQuestionImage(file);

    expect(result.url).toMatch(/^\/uploads\/questions\/[0-9a-f-]+\.webp$/);
    const stored = await fs.readFile(path.join(tmpDir, "questions", path.basename(result.url)));
    const meta = await sharp(stored).metadata();
    expect(meta.format).toBe("webp");
    expect(meta.width).toBe(32);
  });

  it("downscales oversized images preserving aspect ratio", async () => {
    const png = await sharp({
      create: { width: 2000, height: 1000, channels: 3, background: { r: 0, g: 0, b: 255 } }
    }).png().toBuffer();
    const file = fakeFile({ buffer: png, size: png.length });

    const result = await service.saveQuestionImage(file);

    const stored = await fs.readFile(path.join(tmpDir, "questions", path.basename(result.url)));
    const meta = await sharp(stored).metadata();
    expect(meta.width).toBe(1280);
    expect(meta.height).toBe(640);
  });

  it("deleteQuestionImages removes stored files and ignores foreign URLs", async () => {
    const png = await sharp({
      create: { width: 8, height: 8, channels: 3, background: { r: 1, g: 2, b: 3 } }
    }).png().toBuffer();
    const { url } = await service.saveQuestionImage(fakeFile({ buffer: png, size: png.length }));
    const storedPath = path.join(tmpDir, "questions", path.basename(url));
    await expect(fs.access(storedPath)).resolves.toBeUndefined();

    await service.deleteQuestionImages([url, null, undefined, "https://example.com/x.png", "/uploads/questions/missing.webp"]);

    await expect(fs.access(storedPath)).rejects.toThrow();
  });
});
