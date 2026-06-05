import { ResultsService } from "./results.service.js";
import { ResultsRepository } from "./results.repository.js";

describe("ResultsService", () => {
  it("creates a service instance", () => {
    const service = new ResultsService(new ResultsRepository());
    expect(service).toBeInstanceOf(ResultsService);
  });
});

