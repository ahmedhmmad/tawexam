import { AuthService } from "./auth.service.js";
import { AuthRepository } from "./auth.repository.js";

describe("AuthService", () => {
  it("creates a service instance", () => {
    const service = new AuthService(new AuthRepository());
    expect(service).toBeInstanceOf(AuthService);
  });
});

