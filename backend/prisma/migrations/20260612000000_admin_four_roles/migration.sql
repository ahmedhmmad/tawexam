-- Replace the 3-role AdminRole enum with the 4 tiered roles, remapping
-- existing accounts: EXAM_MANAGER -> ADMIN, VIEWER -> SUPERVISOR.
--
-- Postgres cannot drop enum values that are still referenced, so we recreate
-- the type and convert the column with a CASE map. This same file is safe to
-- run by hand on the production DB (which deploys via `prisma db push`) BEFORE
-- the deploy, after which db push sees a matching enum and does nothing.

ALTER TYPE "AdminRole" RENAME TO "AdminRole_old";

CREATE TYPE "AdminRole" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'SUPERVISOR', 'TEACHER');

ALTER TABLE "AdminUser"
  ALTER COLUMN "role" TYPE "AdminRole"
  USING (
    CASE "role"::text
      WHEN 'EXAM_MANAGER' THEN 'ADMIN'
      WHEN 'VIEWER' THEN 'SUPERVISOR'
      ELSE "role"::text
    END
  )::"AdminRole";

DROP TYPE "AdminRole_old";
