export interface QuestionImportRow {
  question_text: string;
  choice_a: string;
  choice_b: string;
  choice_c?: string;
  choice_d?: string;
  correct_answer: "A" | "B" | "C" | "D";
  explanation?: string;
  difficulty: "easy" | "medium" | "hard";
  category: string;
  question_order: number;
}

