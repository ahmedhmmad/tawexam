/** Canonical exam-activity event types. */
export const ActivityEvent = {
  STUDENT_LOGIN: "STUDENT_LOGIN",
  STUDENT_LOGOUT: "STUDENT_LOGOUT",
  EXAM_OPENED: "EXAM_OPENED",
  EXAM_STARTED: "EXAM_STARTED",
  EXAM_SUBMITTED: "EXAM_SUBMITTED",
  EXAM_AUTO_SUBMITTED: "EXAM_AUTO_SUBMITTED",
  EXAM_ABANDONED: "EXAM_ABANDONED",
  APP_BACKGROUNDED: "APP_BACKGROUNDED",
  APP_FOREGROUNDED: "APP_FOREGROUNDED",
  INTERNET_DISCONNECTED: "INTERNET_DISCONNECTED",
  INTERNET_RESTORED: "INTERNET_RESTORED",
  SYNC_QUEUED: "SYNC_QUEUED",
  SYNC_COMPLETED: "SYNC_COMPLETED",
  SESSION_RESUMED: "SESSION_RESUMED",
  ATTEMPT_EXHAUSTED: "ATTEMPT_EXHAUSTED",
  SUSPICIOUS_ACTIVITY: "SUSPICIOUS_ACTIVITY"
} as const;

export type ActivityEventType = (typeof ActivityEvent)[keyof typeof ActivityEvent];

/**
 * Events a STUDENT client is allowed to self-report. Authoritative events
 * (login/logout/started/submitted/auto-submitted/attempt-exhausted) are
 * written server-side only, so a student can't forge them.
 */
export const CLIENT_REPORTABLE_EVENTS: readonly string[] = [
  ActivityEvent.EXAM_OPENED,
  ActivityEvent.EXAM_ABANDONED,
  ActivityEvent.APP_BACKGROUNDED,
  ActivityEvent.APP_FOREGROUNDED,
  ActivityEvent.INTERNET_DISCONNECTED,
  ActivityEvent.INTERNET_RESTORED,
  ActivityEvent.SYNC_QUEUED,
  ActivityEvent.SYNC_COMPLETED,
  ActivityEvent.SESSION_RESUMED,
  ActivityEvent.SUSPICIOUS_ACTIVITY
];

/** Events that count toward a session's "suspicious" tally on the dashboard. */
export const SUSPICIOUS_EVENTS: readonly string[] = [
  ActivityEvent.EXAM_ABANDONED,
  ActivityEvent.APP_BACKGROUNDED,
  ActivityEvent.SUSPICIOUS_ACTIVITY
];
