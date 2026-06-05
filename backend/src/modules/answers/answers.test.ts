import { AnswersService } from "./answers.service.js";
import { AnswersRepository } from "./answers.repository.js";

describe("AnswersService", () => {
  it("creates a service instance", () => {
    const service = new AnswersService(new AnswersRepository());
    expect(service).toBeInstanceOf(AnswersService);
  });
});

