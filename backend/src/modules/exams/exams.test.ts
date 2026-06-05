import { ExamsService } from "./exams.service.js";
import { ExamsRepository } from "./exams.repository.js";

describe("ExamsService", () => {
  it("creates a service instance", () => {
    const service = new ExamsService(new ExamsRepository());
    expect(service).toBeInstanceOf(ExamsService);
  });
});

