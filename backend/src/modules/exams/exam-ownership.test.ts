import { AdminRole } from "@prisma/client";

import { assertExamOwnership, isTeacher } from "./exam-ownership.js";

describe("exam ownership gating", () => {
  it("identifies teachers", () => {
    expect(isTeacher({ id: "1", role: AdminRole.TEACHER })).toBe(true);
    expect(isTeacher({ id: "1", role: AdminRole.ADMIN })).toBe(false);
    expect(isTeacher({ id: "1", role: AdminRole.SUPER_ADMIN })).toBe(false);
    expect(isTeacher(undefined)).toBe(false);
  });

  it("is a no-op for non-teacher roles (no DB lookup, never throws)", async () => {
    // SUPER_ADMIN / ADMIN / SUPERVISOR bypass ownership entirely
    await expect(
      assertExamOwnership("any-exam", { id: "1", role: AdminRole.SUPER_ADMIN })
    ).resolves.toBeUndefined();
    await expect(
      assertExamOwnership("any-exam", { id: "1", role: AdminRole.ADMIN })
    ).resolves.toBeUndefined();
    await expect(assertExamOwnership("any-exam", undefined)).resolves.toBeUndefined();
  });
});
