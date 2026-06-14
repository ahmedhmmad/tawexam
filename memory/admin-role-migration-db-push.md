---
name: admin-role-migration-db-push
description: Production deploys Prisma via `db push`, so enum changes need a manual SQL remap first
metadata:
  type: project
---

TawExam production (docker-compose `backend` service) runs `npx prisma db push --skip-generate` on start, **not** `prisma migrate deploy`. So files under `backend/prisma/migrations/` are NOT auto-applied in production.

Consequence for enum changes (Postgres can't drop in-use enum values): before deploying a schema with changed enum members, run the remap SQL **by hand** on the production DB first, then `db push` sees a matching enum and is a no-op.

The 4-role admin migration (`SUPER_ADMIN/ADMIN/SUPERVISOR/TEACHER`, replacing `EXAM_MANAGER→ADMIN`, `VIEWER→SUPERVISOR`) lives at `backend/prisma/migrations/20260612000000_admin_four_roles/migration.sql` and is written to be runnable directly as that pre-deploy script (rename type → create new → ALTER COLUMN with CASE map → drop old). See [[admin-multi-role-feature]].
