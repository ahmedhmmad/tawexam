import { QuestionsService } from "./questions.service.js";
import { QuestionsRepository } from "./questions.repository.js";

describe("QuestionsService", () => {
  it("creates a service instance", () => {
    const service = new QuestionsService(new QuestionsRepository());
    expect(service).toBeInstanceOf(QuestionsService);
  });
});

