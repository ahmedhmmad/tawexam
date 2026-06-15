import { ActivityEvent, CLIENT_REPORTABLE_EVENTS } from "./activity-log.events.js";
import { activityReportSchema } from "./activity-log.schema.js";

describe("activity-log client reporting security", () => {
  it("accepts a whitelisted client event", () => {
    const parsed = activityReportSchema.safeParse({ eventType: ActivityEvent.APP_BACKGROUNDED });
    expect(parsed.success).toBe(true);
  });

  it("rejects authoritative server-only events (no forging by students)", () => {
    for (const forged of [
      ActivityEvent.STUDENT_LOGIN,
      ActivityEvent.EXAM_STARTED,
      ActivityEvent.EXAM_SUBMITTED,
      ActivityEvent.EXAM_AUTO_SUBMITTED,
      ActivityEvent.ATTEMPT_EXHAUSTED
    ]) {
      expect(activityReportSchema.safeParse({ eventType: forged }).success).toBe(false);
    }
  });

  it("only exposes safe events to clients", () => {
    expect(CLIENT_REPORTABLE_EVENTS).not.toContain(ActivityEvent.STUDENT_LOGIN);
    expect(CLIENT_REPORTABLE_EVENTS).not.toContain(ActivityEvent.EXAM_SUBMITTED);
    expect(CLIENT_REPORTABLE_EVENTS).toContain(ActivityEvent.APP_BACKGROUNDED);
    expect(CLIENT_REPORTABLE_EVENTS).toContain(ActivityEvent.INTERNET_DISCONNECTED);
  });
});
