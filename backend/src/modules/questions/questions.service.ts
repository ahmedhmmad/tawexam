import { Difficulty } from "@prisma/client";
import xlsx from "xlsx";

import { AppError } from "../../utils/app-error.js";
import { ensureXlsxFile, type ParsedRowError } from "../../utils/excelParser.js";
import { extractInCellImages, type CellImage } from "../../utils/excelImageExtractor.js";
import { uploadsService } from "../uploads/uploads.service.js";
import { QuestionsRepository, type QuestionInput } from "./questions.repository.js";
import { questionImportRowSchema } from "./questions.schema.js";

function normalizeImageUrl(value: string | undefined): string | null | undefined {
  if (value === undefined) return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

/** Cells holding in-cell images parse as spreadsheet error values — treat as empty text. */
function cleanCellText(value: unknown): string {
  const text = `${value ?? ""}`.trim();
  return text === "#VALUE!" ? "" : text;
}

const CHOICE_LABELS = ["A", "B", "C", "D"] as const;
type ChoiceLabel = (typeof CHOICE_LABELS)[number];

/** Per-row images extracted from the workbook, mapped by the column they sit in. */
interface RowImages {
  question?: CellImage;
  choices: Partial<Record<ChoiceLabel, CellImage>>;
}

/** Which header names attach an image to which field. */
const IMAGE_COLUMN_TARGETS: Record<string, "question" | ChoiceLabel> = {
  question_text: "question",
  image_url: "question",
  choice_a: "A",
  choice_a_image: "A",
  choice_b: "B",
  choice_b_image: "B",
  choice_c: "C",
  choice_c_image: "C",
  choice_d: "D",
  choice_d_image: "D"
};

interface ParsedQuestionRow {
  rowNumber: number;
  data: ReturnType<typeof questionImportRowSchema.parse>;
  images: RowImages;
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

  async validateWorkbook(file: Express.Multer.File) {
    const { rows, errors } = await this.parseQuestionWorkbook(file);
    return {
      validRows: rows.map((row) => ({
        ...row.data,
        has_question_image: row.images.question !== undefined || Boolean(row.data.image_url?.trim()),
        choices_with_images: CHOICE_LABELS.filter((label) => row.images.choices[label] !== undefined)
      })),
      errors
    };
  }

  async importWorkbook(examId: string, file: Express.Multer.File, mode: "append" | "replace") {
    const { rows, errors } = await this.parseQuestionWorkbook(file);
    if (rows.length === 0) {
      throw new AppError("No valid question rows found", 400, "NO_VALID_ROWS", errors);
    }

    const prepared: QuestionInput[] = [];
    for (const { data: row, images } of rows) {
      const questionImageUrl =
        (await this.storeCellImage(images.question)) ?? normalizeImageUrl(row.image_url);

      const choiceImageUrls: Partial<Record<ChoiceLabel, string | null | undefined>> = {
        A: (await this.storeCellImage(images.choices.A)) ?? normalizeImageUrl(row.choice_a_image),
        B: (await this.storeCellImage(images.choices.B)) ?? normalizeImageUrl(row.choice_b_image),
        C: (await this.storeCellImage(images.choices.C)) ?? normalizeImageUrl(row.choice_c_image),
        D: (await this.storeCellImage(images.choices.D)) ?? normalizeImageUrl(row.choice_d_image)
      };

      const choiceTexts: Record<ChoiceLabel, string> = {
        A: row.choice_a,
        B: row.choice_b,
        C: cleanCellText(row.choice_c),
        D: cleanCellText(row.choice_d)
      };

      prepared.push({
        text: row.question_text,
        imageUrl: questionImageUrl,
        difficulty: row.difficulty.toUpperCase() as Difficulty,
        category: row.category,
        orderIndex: row.question_order,
        explanation: row.explanation,
        choices: CHOICE_LABELS.filter(
          (label) => choiceTexts[label].length > 0 || choiceImageUrls[label]
        ).map((label) => ({
          label,
          text: choiceTexts[label],
          imageUrl: choiceImageUrls[label],
          isCorrect: row.correct_answer === label
        }))
      });
    }

    if (mode === "replace") {
      await this.repository.replaceForExam(examId, prepared);
    } else {
      await Promise.all(prepared.map((row) => this.repository.create(examId, row)));
    }

    return {
      imported: prepared.length,
      errors,
      preview: rows.map((row) => row.data)
    };
  }

  /**
   * Parses the workbook text via `xlsx` and merges in any in-cell images
   * (Excel "Place in Cell" pictures) by sheet row + header column. A question
   * or required choice is valid when it has text OR an image.
   */
  private async parseQuestionWorkbook(
    file: Express.Multer.File
  ): Promise<{ rows: ParsedQuestionRow[]; errors: ParsedRowError[] }> {
    ensureXlsxFile(file.originalname, file.mimetype);

    const workbook = xlsx.read(file.buffer, { type: "buffer" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const jsonRows = xlsx.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: "" });
    const cellImages = await extractInCellImages(file.buffer);

    // Header text by column letter (header row = sheet row 1)
    const headerByColumn = new Map<string, string>();
    for (const cellRef of Object.keys(sheet)) {
      const match = /^([A-Z]+)1$/.exec(cellRef);
      if (!match) continue;
      const value = (sheet[cellRef] as { v?: unknown }).v;
      headerByColumn.set(match[1], `${value ?? ""}`.trim().toLowerCase());
    }

    // Group extracted images by sheet row, mapped to question/choice fields
    const imagesByRow = new Map<number, RowImages>();
    for (const [cellRef, image] of cellImages) {
      const refMatch = /^([A-Z]+)(\d+)$/.exec(cellRef);
      if (!refMatch) continue;
      const header = headerByColumn.get(refMatch[1]);
      const target = header ? IMAGE_COLUMN_TARGETS[header] : undefined;
      if (!target) continue;
      const rowNumber = Number(refMatch[2]);
      const entry = imagesByRow.get(rowNumber) ?? { choices: {} };
      if (target === "question") {
        entry.question = image;
      } else {
        entry.choices[target] = image;
      }
      imagesByRow.set(rowNumber, entry);
    }

    const rows: ParsedQuestionRow[] = [];
    const errors: ParsedRowError[] = [];
    const seenOrders = new Set<number>();

    jsonRows.forEach((rawRow) => {
      // sheet_to_json attaches the 0-based sheet row as __rowNum__
      const rowNumber = ((rawRow as { __rowNum__?: number }).__rowNum__ ?? 0) + 1;
      const images = imagesByRow.get(rowNumber) ?? { choices: {} };

      const sanitized: Record<string, unknown> = { ...rawRow };
      for (const key of ["question_text", "choice_a", "choice_b", "choice_c", "choice_d"]) {
        if (key in sanitized) sanitized[key] = cleanCellText(sanitized[key]);
      }

      const parsed = questionImportRowSchema.safeParse(sanitized);
      if (!parsed.success) {
        errors.push({
          rowNumber,
          errors: parsed.error.issues.map((issue) => `${issue.path.join(".")}: ${issue.message}`)
        });
        return;
      }

      // Text-or-image presence checks (schema allows empty text for image cells)
      const rowErrors: string[] = [];
      if (parsed.data.question_text.length === 0 && !images.question && !parsed.data.image_url?.trim()) {
        rowErrors.push("question_text: text or an in-cell image is required");
      }
      const hasChoice = (label: ChoiceLabel, text: string, urlColumn?: string) =>
        text.length > 0 || images.choices[label] !== undefined || Boolean(urlColumn?.trim());
      if (!hasChoice("A", parsed.data.choice_a, parsed.data.choice_a_image)) {
        rowErrors.push("choice_a: text or an in-cell image is required");
      }
      if (!hasChoice("B", parsed.data.choice_b, parsed.data.choice_b_image)) {
        rowErrors.push("choice_b: text or an in-cell image is required");
      }
      const correctLabel = parsed.data.correct_answer;
      const correctText: Record<ChoiceLabel, string> = {
        A: parsed.data.choice_a,
        B: parsed.data.choice_b,
        C: cleanCellText(parsed.data.choice_c),
        D: cleanCellText(parsed.data.choice_d)
      };
      const correctUrl: Record<ChoiceLabel, string | undefined> = {
        A: parsed.data.choice_a_image,
        B: parsed.data.choice_b_image,
        C: parsed.data.choice_c_image,
        D: parsed.data.choice_d_image
      };
      if (!hasChoice(correctLabel, correctText[correctLabel], correctUrl[correctLabel])) {
        rowErrors.push(`correct_answer: choice ${correctLabel} has no text or image`);
      }
      if (seenOrders.has(parsed.data.question_order)) {
        rowErrors.push(`question_order: duplicate order ${parsed.data.question_order} in this file`);
      }

      if (rowErrors.length > 0) {
        errors.push({ rowNumber, errors: rowErrors });
        return;
      }

      seenOrders.add(parsed.data.question_order);
      rows.push({ rowNumber, data: parsed.data, images });
    });

    return { rows, errors };
  }

  /** Runs an extracted cell image through the standard upload pipeline. */
  private async storeCellImage(image: CellImage | undefined): Promise<string | undefined> {
    if (!image) return undefined;
    const mimetype = image.extension === "jpg" ? "image/jpeg" : `image/${image.extension}`;
    const { url } = await uploadsService.saveQuestionImage({
      buffer: image.buffer,
      mimetype,
      size: image.buffer.length,
      originalname: `excel-import.${image.extension}`
    } as Express.Multer.File);
    return url;
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
