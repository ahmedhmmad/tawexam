import { StudentsService } from "./students.service.js";
import { StudentsRepository } from "./students.repository.js";

describe("StudentsService", () => {
  it("creates a service instance", () => {
    const service = new StudentsService(new StudentsRepository());
    expect(service).toBeInstanceOf(StudentsService);
  });
});

