import path from "node:path";
import { z } from "zod";
import xlsx from "xlsx";

import { AppError } from "./app-error.js";

export interface ParsedRowError {
  rowNumber: number;
  errors: string[];
}

export interface ParsedSheetResult<T> {
  validRows: T[];
  errors: ParsedRowError[];
}

export function ensureXlsxFile(filename: string, mimetype: string): void {
  const extension = path.extname(filename).toLowerCase();
  const allowedExtensions = new Set([".xlsx", ".xls"]);
  const allowedMimeTypes = new Set([
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.ms-excel"
  ]);

  if (!allowedExtensions.has(extension) || !allowedMimeTypes.has(mimetype)) {
    throw new AppError("Only Excel files are allowed", 400, "INVALID_FILE_TYPE");
  }
}

export function parseWorkbook<T>(
  fileBuffer: Buffer,
  rowSchema: z.ZodSchema<T>
): ParsedSheetResult<T> {
  const workbook = xlsx.read(fileBuffer, { type: "buffer" });
  const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = xlsx.utils.sheet_to_json<Record<string, unknown>>(firstSheet, {
    defval: ""
  });

  const validRows: T[] = [];
  const errors: ParsedRowError[] = [];

  rows.forEach((row, index) => {
    const parsed = rowSchema.safeParse(row);
    if (parsed.success) {
      validRows.push(parsed.data);
      return;
    }

    errors.push({
      rowNumber: index + 2,
      errors: parsed.error.issues.map((issue) => `${issue.path.join(".")}: ${issue.message}`)
    });
  });

  return { validRows, errors };
}

