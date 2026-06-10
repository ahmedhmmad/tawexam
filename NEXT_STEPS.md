# TawExam — Next Steps

> Created: June 10, 2026
> Author: code analysis of the current `main` branch
>
> This supersedes the stale `SRS_GAP_ANALYSIS.md` (June 5), which predates the
> admin-panel build-out. The admin pages it lists as "scaffolds" are now real:
> `exams_list_page.dart` (535 lines), `students_page.dart` (451),
> `questions_page.dart` (394), `results_page.dart` (236),
> `admin_results_overview_page.dart` (269).

---

## 1. Where the project actually stands

### Solid and shipped
- **Backend** — all modules present and deployed (`auth`, `students`, `exams`,
  `questions`, `answers`, `sessions`, `results`, `monitoring`). RBAC, audit log,
  rate limiting, JWT refresh, WebSocket auth, request IDs, Zod validation, an
  analytics endpoint, and per-module `*.test.ts` smoke tests all exist.
- **Student app** — full offline-first exam flow: login → instructions →
  timed question navigation with palette/flagging → local Hive persistence →
  background sync (Workmanager + exponential backoff) → submit → score-only
  result. Server-time-anchored countdown, connectivity indicator, session
  persistence across restarts.
- **Admin web** — exam CRUD with status transitions, student management with
  Excel import/export + pagination, manual + Excel question management, a
  per-attempt results table with Excel export, and a results overview page.
- **Infra** — Docker Compose (postgres/redis/backend/nginx), TLS, auto
  migrations, live at `tawjihi.megaserv.xyz`.

### Uncommitted work in progress (working tree)
Minor polish, not yet committed:
- `lib/main.dart` — instant native-style loading splash before DI finishes.
- `instructions_page.dart` / `student_home_page.dart` — friendlier, shortened
  Arabic error messages (hide raw status/stack from students).
- `pubspec.yaml` — version bump to `1.1.2+6`.

**Action:** commit these as a small "UX: splash + friendly errors" commit so the
tree is clean before starting the work below.

---

## 2. The biggest planned feature — not started

### Image support for questions & choices
`PROJECT_SUMMARY.md` specs this in detail, but **nothing is implemented yet** —
`imageUrl` / `image_url` appears nowhere in `lib/` or `backend/src/`. `multer`
is already a backend dependency, so the upload plumbing has a head start.

Recommended order (≈12–15h per the summary's own estimate):
1. **Schema** — add nullable `imageUrl String?` to `Question` and `Choice` in
   `backend/prisma/schema.prisma`; migrate.
2. **Backend** — `POST /admin/uploads/question-image` (multipart, PNG/JPG/WEBP,
   ≤2MB), static `/uploads/*` serving from the mounted volume, MIME/size/
   dimension validation. Consider adding `sharp` to auto-resize to a max
   dimension (not currently a dependency).
3. **Admin** — image picker + preview on the question form and per choice;
   thumbnail in the question list; new Excel template columns.
4. **Mobile** — add `imageUrl` to `Question`/`AnswerOption` entities + models,
   render with caching, and **prefetch all images at session start** so offline
   review still works. This needs a `cached_network_image` dependency (not yet
   in `pubspec.yaml`).

**Decisions to lock before starting** (open questions from the summary): SVG
support (recommend no — raster only), auto-resize on upload (recommend yes), and
offline strategy (recommend prefetch-at-session-start over lazy load).

---

## 3. Remaining functional gaps (prioritized)

### High — completes the admin story
- **Live monitoring UI (R13.2/13.3).** The backend Socket.IO `/admin/monitoring`
  namespace emits `session:started` / `answer:saved` / `session:ended`, but
  **no Flutter client consumes it** — there is no socket reference anywhere in
  `lib/`. Build an admin monitoring page (active sessions, per-student progress,
  remaining time) with a `socket_io_client` dependency and reconnect-with-
  backoff. This is the one backend capability with zero front-end.
- **Results analytics dashboard (R12.2).** `results_page.dart` is a data table
  only — no summary cards or histogram, despite the backend analytics endpoint
  returning average score / pass rate / completion. Add summary cards + a score
  distribution chart (needs a charting dep, e.g. `fl_chart`). Wire to the
  existing analytics endpoint.

### Medium — correctness & access control
- **Role-based nav hiding (R8.2).** `admin_shell_page.dart` shows every
  destination unconditionally; there is no `role`/`VIEWER`/`SUPER_ADMIN` check.
  Hide management/destructive actions from `VIEWER` accounts (the backend already
  enforces 403, but the UI shouldn't offer the action).
- **Auto-assign `orderIndex` on question import (R11.2).** Don't trust the
  Excel `question_order` column; assign sequential indices server-side per exam.
- **Standardize upload limit to 10MB (R14.2).** Students import is 5MB; unify
  Multer config across endpoints (and the new image endpoint).
- **FK existence checks on answer sync (R14.4).** Validate `questionId` /
  `choiceId` belong to the session's exam before persisting synced answers.

### Lower — polish & hardening
- **"Next scheduled exam" date (R2.1)** in the student no-exam state — needs the
  backend to return `nextExamDate`.
- **XSS sanitization middleware (R14.3)** beyond Helmet headers.
- **Accessibility pass (R20).** Add `Semantics`/`semanticLabel` to choice tiles,
  palette items, and buttons; verify 48×48dp touch targets on the palette grid;
  audit contrast ratios; test text scaling to 200%.
- **Grade in a transaction (R21).** Wrap `ResultsService.gradeSession()` in an
  explicit `$transaction` for safety.

---

## 4. Testing & quality (currently thin)

Only 6 Flutter test files exist (`auth`, `exam` cubits, two usecases, sync
service, widget smoke test) and backend tests are per-module smoke coverage
that `PROJECT_MEMORY.md` notes still need `--forceExit`.

- Add **Supertest + mocked-Prisma integration tests** for the critical paths:
  session creation/reuse, attempt counting, grading correctness, answer sync
  with ownership validation.
- Add Flutter tests for the **countdown service** (server-time drift) and the
  **sync queue/backoff**, the two areas most likely to break silently during a
  real exam.
- Before the next release, run `flutter analyze` + `flutter test` and the
  backend `npm run build` + `npm test` as a release gate.

---

## 5. Recommended sequence

1. Commit the in-flight splash/error polish (clean the tree).
2. Decide image-feature open questions, then implement image support end-to-end
   (highest user-visible value — unblocks math/science/biology exams).
3. Build the live monitoring page (only backend feature with no UI).
4. Add the results analytics dashboard (charting dep + summary cards).
5. Role-based nav hiding + the medium backend hardening items.
6. Strengthen tests, then accessibility + remaining polish.

---

## 6. New dependencies this work will introduce

| Area | Package | For |
|------|---------|-----|
| Mobile | `cached_network_image` | Question/choice image caching & offline review |
| Mobile | `socket_io_client` | (only if a student-side live feature is added — not required for admin web) |
| Admin web | `socket_io_client` | Live monitoring client |
| Admin web | `fl_chart` (or similar) | Score distribution histogram |
| Backend | `sharp` | Server-side image resize/validation (optional but recommended) |
