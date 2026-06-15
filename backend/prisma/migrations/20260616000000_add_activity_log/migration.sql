-- Event-based exam-activity monitoring table (no FK relations by design).
CREATE TABLE "ActivityLog" (
  "id" TEXT NOT NULL,
  "userId" TEXT,
  "studentId" TEXT,
  "examId" TEXT,
  "eventType" TEXT NOT NULL,
  "description" TEXT,
  "metadata" JSONB NOT NULL DEFAULT '{}',
  "ipAddress" TEXT,
  "deviceIdentifier" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ActivityLog_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ActivityLog_examId_createdAt_idx" ON "ActivityLog"("examId", "createdAt");
CREATE INDEX "ActivityLog_studentId_createdAt_idx" ON "ActivityLog"("studentId", "createdAt");
CREATE INDEX "ActivityLog_eventType_createdAt_idx" ON "ActivityLog"("eventType", "createdAt");
CREATE INDEX "ActivityLog_createdAt_idx" ON "ActivityLog"("createdAt");
