import { SessionsService } from "./sessions.service.js";
import { SessionsRepository } from "./sessions.repository.js";

describe("SessionsService", () => {
  it("creates a service instance", () => {
    const service = new SessionsService(new SessionsRepository());
    expect(service).toBeInstanceOf(SessionsService);
  });

  describe("getRemainingWindowSeconds (per-student exam window)", () => {
    const MINUTE = 60 * 1000;

    function serviceWithFirstSession(startedAt: Date | null) {
      const repository = {
        findFirstSession: async () => (startedAt ? { startedAt } : null)
      } as unknown as SessionsRepository;
      return new SessionsService(repository);
    }

    function exam(overrides: Partial<{ startAt: Date; endAt: Date; durationMinutes: number }> = {}) {
      const now = Date.now();
      return {
        id: "exam1",
        startAt: new Date(now - 120 * MINUTE),
        endAt: new Date(now + 120 * MINUTE),
        durationMinutes: 60,
        ...overrides
      };
    }

    it("grants the full duration to a first-time starter even long after startAt", async () => {
      const service = serviceWithFirstSession(null);
      const remaining = await service.getRemainingWindowSeconds(exam(), "s1");
      expect(remaining).toBeGreaterThanOrEqual(60 * 60 - 1);
      expect(remaining).toBeLessThanOrEqual(60 * 60);
    });

    it("anchors retries to the student's first session", async () => {
      const service = serviceWithFirstSession(new Date(Date.now() - 30 * MINUTE));
      const remaining = await service.getRemainingWindowSeconds(exam(), "s1");
      // 60 min duration - 30 min elapsed since first start ≈ 30 min left
      expect(remaining).toBeGreaterThanOrEqual(30 * 60 - 2);
      expect(remaining).toBeLessThanOrEqual(30 * 60);
    });

    it("returns 0 once the student's personal window is used up", async () => {
      const service = serviceWithFirstSession(new Date(Date.now() - 61 * MINUTE));
      const remaining = await service.getRemainingWindowSeconds(exam(), "s1");
      expect(remaining).toBeLessThanOrEqual(0);
    });

    it("caps remaining time at the exam endAt", async () => {
      const service = serviceWithFirstSession(null);
      const remaining = await service.getRemainingWindowSeconds(
        exam({ endAt: new Date(Date.now() + 10 * MINUTE) }),
        "s1"
      );
      expect(remaining).toBeLessThanOrEqual(10 * 60);
      expect(remaining).toBeGreaterThanOrEqual(10 * 60 - 2);
    });

    it("returns 0 after endAt has passed", async () => {
      const service = serviceWithFirstSession(null);
      const remaining = await service.getRemainingWindowSeconds(
        exam({ endAt: new Date(Date.now() - MINUTE) }),
        "s1"
      );
      expect(remaining).toBe(0);
    });
  });
});
