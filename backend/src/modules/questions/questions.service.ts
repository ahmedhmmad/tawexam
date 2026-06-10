import { Difficulty } from "@prisma/client";
import xlsx from "xlsx";

import { AppError } from "../../utils/app-error.js";
import { ensureXlsxFile, parseWorkbook } from "../../utils/excelParser.js";
import { uploadsService } from "../uploads/uploads.service.js";
import { QuestionsRepository, type QuestionInput } from "./questions.repository.js";
import { questionImportRowSchema } from "./questions.schema.js";

function normalizeImageUrl(value: string | undefined): string | null | undefined {
  if (value === undefined) return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

export class QuestionsService {
  constructor(private readonly repository: QuestionsRepository = new QuestionsRepository()) {}

  listByExam(examId: string) {
    return this.repository.listByExam(examId);
  }

  create(examId: string, payload: QuestionInput) {
    return this.repository.create(examId, payload);
  }

  update(id: string, payload: Partial<QuestionInput>) {
    return this.repository.update(id, payload);
  }

  async delete(id: string) {
    const question = await this.repository.findById(id);
    const deleted = await this.repository.delete(id);
    if (question) {
      await uploadsService.deleteQuestionImages([
        question.imageUrl,
        ...question.choices.map((choice) => choice.imageUrl)
      ]);
    }
    return deleted;
  }

  validateWorkbook(file: Express.Multer.File) {
    ensureXlsxFile(file.originalname, file.mimetype);
    return parseWorkbook(file.buffer, questionImportRowSchema);
  }

  async importWorkbook(examId: string, file: Express.Multer.File, mode: "append" | "replace") {
    const parsed = this.validateWorkbook(file);
    const prepared: QuestionInput[] = parsed.validRows.map((row) => ({
      text: row.question_text,
      imageUrl: normalizeImageUrl(row.image_url),
      difficulty: row.difficulty.toUpperCase() as Difficulty,
      category: row.category,
      orderIndex: row.question_order,
      explanation: row.explanation,
      choices: [
        { label: "A", text: row.choice_a, imageUrl: normalizeImageUrl(row.choice_a_image), isCorrect: row.correct_answer === "A" },
        { label: "B", text: row.choice_b, imageUrl: normalizeImageUrl(row.choice_b_image), isCorrect: row.correct_answer === "B" },
        ...(row.choice_c ? [{ label: "C", text: row.choice_c, imageUrl: normalizeImageUrl(row.choice_c_image), isCorrect: row.correct_answer === "C" }] : []),
        ...(row.choice_d ? [{ label: "D", text: row.choice_d, imageUrl: normalizeImageUrl(row.choice_d_image), isCorrect: row.correct_answer === "D" }] : [])
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
        image_url: "",
        choice_a: "",
        choice_a_image: "",
        choice_b: "",
        choice_b_image: "",
        choice_c: "",
        choice_c_image: "",
        choice_d: "",
        choice_d_image: "",
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
