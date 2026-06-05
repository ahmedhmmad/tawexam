import { Difficulty } from "@prisma/client";
import xlsx from "xlsx";

import { AppError } from "../../utils/app-error.js";
import { ensureXlsxFile, parseWorkbook } from "../../utils/excelParser.js";
import { QuestionsRepository } from "./questions.repository.js";
import { questionImportRowSchema } from "./questions.schema.js";

export class QuestionsService {
  constructor(private readonly repository: QuestionsRepository = new QuestionsRepository()) {}

  listByExam(examId: string) {
    return this.repository.listByExam(examId);
  }

  create(examId: string, payload: {
    text: string;
    difficulty: Difficulty;
    category: string;
    orderIndex: number;
    explanation?: string;
    choices: Array<{ label: string; text: string; isCorrect: boolean }>;
  }) {
    return this.repository.create(examId, payload);
  }

  update(id: string, payload: Partial<{
    text: string;
    difficulty: Difficulty;
    category: string;
    orderIndex: number;
    explanation?: string;
    choices: Array<{ label: string; text: string; isCorrect: boolean }>;
  }>) {
    return this.repository.update(id, payload);
  }

  delete(id: string) {
    return this.repository.delete(id);
  }

  validateWorkbook(file: Express.Multer.File) {
    ensureXlsxFile(file.originalname, file.mimetype);
    return parseWorkbook(file.buffer, questionImportRowSchema);
  }

  async importWorkbook(examId: string, file: Express.Multer.File, mode: "append" | "replace") {
    const parsed = this.validateWorkbook(file);
    const prepared = parsed.validRows.map((row) => ({
      text: row.question_text,
      difficulty: row.difficulty.toUpperCase() as Difficulty,
      category: row.category,
      orderIndex: row.question_order,
      explanation: row.explanation,
      choices: [
        { label: "A", text: row.choice_a, isCorrect: row.correct_answer === "A" },
        { label: "B", text: row.choice_b, isCorrect: row.correct_answer === "B" },
        ...(row.choice_c ? [{ label: "C", text: row.choice_c, isCorrect: row.correct_answer === "C" }] : []),
        ...(row.choice_d ? [{ label: "D", text: row.choice_d, isCorrect: row.correct_answer === "D" }] : [])
      ]
    }));

    if (prepared.length === 0) {
      throw new AppError("No valid question rows found", 400, "NO_VALID_ROWS", parsed.errors);
    }

    if (mode === "replace") {
      await this.repository.replaceForExam(examId, prepared);
    } else {
      await Promise.all(prepared.map((row) => this.repository.create(examId, row)));
    }

    return {
      imported: prepared.length,
      errors: parsed.errors,
      preview: parsed.validRows
    };
  }

  templateWorkbook(): Buffer {
    const workbook = xlsx.utils.book_new();
    const sheet = xlsx.utils.json_to_sheet([
      {
        question_text: "",
        choice_a: "",
        choice_b: "",
        choice_c: "",
        choice_d: "",
        correct_answer: "A",
        explanation: "",
        difficulty: "easy",
        category: "",
        question_order: 1
      }
    ]);
    xlsx.utils.book_append_sheet(workbook, sheet, "Questions");
    return xlsx.write(workbook, { type: "buffer", bookType: "xlsx" });
  }
}

