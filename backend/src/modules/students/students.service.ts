import xlsx from "xlsx";

import { AppError } from "../../utils/app-error.js";
import { ensureXlsxFile, parseWorkbook } from "../../utils/excelParser.js";
import { hashPassword } from "../../utils/password.js";
import type { StudentFilters, StudentImportRow } from "./students.types.js";
import { studentImportRowSchema } from "./students.schema.js";
import { StudentsRepository } from "./students.repository.js";

export class StudentsService {
  constructor(private readonly repository: StudentsRepository = new StudentsRepository()) {}

  list(filters: StudentFilters) {
    return this.repository.list(filters);
  }

  async create(payload: {
    seatNumber: string;
    fullName: string;
    password: string;
    mobileNo?: string;
    branch?: string;
    schoolName?: string;
    isActive?: boolean;
  }) {
    return this.repository.create({
      seatNumber: payload.seatNumber,
      fullName: payload.fullName,
      passwordHash: await hashPassword(payload.password),
      mobileNo: payload.mobileNo || "",
      branch: payload.branch || "",
      schoolName: payload.schoolName || "",
      isActive: payload.isActive ?? true
    });
  }

  async update(
    id: string,
    payload: Partial<{
      seatNumber: string;
      fullName: string;
      password: string;
      mobileNo: string;
      branch: string;
      schoolName: string;
      isActive: boolean;
    }>
  ) {
    const data: Record<string, unknown> = { ...payload };
    if (payload.password) {
      data.passwordHash = await hashPassword(payload.password);
      delete data.password;
    }
    return this.repository.update(id, data);
  }

  delete(id: string) {
    return this.repository.delete(id);
  }

  async importFromWorkbook(file: Express.Multer.File, defaultBranch?: string): Promise<{
    imported: number;
    validRows: StudentImportRow[];
    errors: Array<{ rowNumber: number; errors: string[] }>;
  }> {
    ensureXlsxFile(file.originalname, file.mimetype);
    if (file.size > 10 * 1024 * 1024) {
      throw new AppError("File exceeds 10MB", 400, "FILE_TOO_LARGE");
    }

    const parsed = parseWorkbook(file.buffer, studentImportRowSchema);
    const validRows: StudentImportRow[] = parsed.validRows.map((row) => ({
      id: String(row.id),
      name: row.name,
      mobile_no: String(row.mobile_no),
      branch: defaultBranch || row.branch || ""
    }));

    const preparedRows = await Promise.all(
      validRows.map(async (row) => ({
        seatNumber: row.id,
        fullName: row.name,
        passwordHash: await hashPassword(row.mobile_no),
        mobileNo: row.mobile_no,
        branch: row.branch || defaultBranch || "",
        schoolName: "",
        isActive: true
      }))
    );

    const imported = preparedRows.length > 0 ? await this.repository.upsertMany(preparedRows) : 0;
    return { imported, validRows, errors: parsed.errors };
  }

  async exportWorkbook(): Promise<Buffer> {
    const students = await this.repository.exportAll();
    const workbook = xlsx.utils.book_new();
    const sheet = xlsx.utils.json_to_sheet(
      students.map((student) => ({
        id: student.seatNumber,
        name: student.fullName,
        mobile_no: (student as any).mobileNo || "",
        isActive: student.isActive
      }))
    );
    xlsx.utils.book_append_sheet(workbook, sheet, "Students");
    return xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
  }

  async resetPassword(id: string, password?: string): Promise<{ password: string }> {
    const generated = password ?? `Tawjihi-${Math.random().toString(36).slice(2, 10)}`;
    await this.repository.update(id, {
      passwordHash: await hashPassword(generated)
    });
    return { password: generated };
  }
}
