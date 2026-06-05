import { SessionsService } from "./sessions.service.js";
import { SessionsRepository } from "./sessions.repository.js";

describe("SessionsService", () => {
  it("creates a service instance", () => {
    const service = new SessionsService(new SessionsRepository());
    expect(service).toBeInstanceOf(SessionsService);
  });
});

