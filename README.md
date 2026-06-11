# TawExam — توجيهي

**Offline-first electronic exam platform for Palestinian Tawjihi (high school) students.**

Admins create timed multiple-choice exams (with optional images for questions and choices) through a web panel; students take them on a mobile app that keeps working even when the internet doesn't — every answer is saved locally first and synced in the background.

| Component | Tech | Entry point |
|---|---|---|
| 📱 Student app (Android) | Flutter + Bloc/Cubit, Hive, Dio | `lib/main.dart` |
| 🖥️ Admin panel (web) | Flutter Web, Material 3, RTL | `lib/main_admin.dart` |
| ⚙️ Backend API | Node.js 20, Express, TypeScript, Prisma | `backend/src/app.ts` |
| 🗄️ Data | PostgreSQL 16, Redis 7 (sessions/refresh tokens) | Docker Compose |

---

## Features

### Student app
- Login by seat number + password, session persists across app restarts
- Branch-aware exam discovery (علمي / أدبي / شرعي / صناعي)
- Timed exam flow: instructions → questions with navigation palette, flagging, and images → review → submit
- **Offline-first**: answers persist to encrypted Hive instantly, sync via a FIFO queue with exponential backoff + Workmanager background sync; exam images are prefetched at session start so they render offline
- Per-student exam window: start any time between `startAt` and `endAt` with the full duration; retries are anchored to the first attempt so quitting never grants extra time
- Submission lock: once submitted (even offline), the exam can't be re-entered while the result waits to sync
- Result visibility controlled by the admin: hidden / score only / full right-wrong breakdown with correct answers
- Arabic UI throughout, all errors mapped to friendly Arabic messages

### Admin panel
- Exam CRUD with scheduling, duration, passing score, max attempts, branch targeting, and status workflow (DRAFT → SCHEDULED → ACTIVE → COMPLETED → ARCHIVED)
- Question management: manual form with per-question and per-choice **image upload** (resized + converted to WEBP server-side), or Excel bulk import with downloadable template
- Student management: CRUD, Excel import/export, password reset, branch filters, pagination
- Per-attempt results table with Excel export
- `showResults` / `showAnswers` toggles per exam

### Backend
- JWT auth (RS256): 15-min access + 7-day refresh stored in Redis, role-based admin access (SUPER_ADMIN / EXAM_MANAGER / VIEWER)
- Zod validation on every route, standard `{ success, data | error }` response shape with `X-Request-Id`
- Audit log for all admin write operations
- Image upload pipeline (multer → sharp: validate, auto-rotate, resize ≤1280px, convert to WEBP ≤2MB)
- Socket.IO namespace for live exam monitoring (JWT-authenticated)
- Rate limiting, helmet, CORS, bcrypt, gzip

---

## Repository layout

```
├── lib/                    # Flutter (student app + admin panel)
│   ├── core/               # DI, networking, storage, sync queue, errors, timer
│   └── features/
│       ├── auth/           # student login
│       ├── exam/           # exam flow (domain/data/presentation)
│       └── admin/          # admin panel pages & cubits
├── backend/
│   ├── prisma/             # schema + migrations
│   └── src/
│       ├── modules/        # auth, students, exams, questions, answers,
│       │                   # sessions, results, monitoring, uploads
│       ├── middlewares/    # auth, rbac, validation, rate limit, errors
│       └── utils/          # audit log, excel parser, api responses
├── test/                   # Flutter tests
├── docker-compose.yml      # postgres + redis + backend
├── nginx/                  # reverse proxy config
└── legal/                  # privacy policy & terms (static pages)
```

The architecture follows Clean Architecture on the Flutter side (domain / data / presentation per feature) and a module-per-resource pattern (router → controller → service → repository) on the backend.

---

## Getting started

### Prerequisites
- Flutter ≥ 3.x, Dart ≥ 3.10
- Node.js 20, Docker + Docker Compose

### 1. Backend (local)

```bash
cp .env.example .env          # fill in DB credentials and JWT keys
docker compose up -d postgres redis
cd backend
npm install
npx prisma db push            # apply schema
npm run dev                   # http://localhost:3003
```

JWT uses RS256 — generate a key pair and reference it from `.env` (see `.env.example`).

### 2. Student app

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3003/api/v1   # Android emulator
```

### 3. Admin panel (web)

```bash
flutter run -d chrome --target=lib/main_admin.dart \
  --dart-define=API_BASE_URL=http://localhost:3003/api/v1
```

---

## Testing

```bash
# Backend (Jest)
cd backend && npm test

# Flutter
flutter analyze
flutter test
```

---

## Production builds & deployment

### Backend
```bash
cd /opt/tawjihi && git pull origin main && docker compose up -d --build backend
```
Migrations apply automatically on container start (`prisma db push`). Uploaded images persist in the `backend_uploads` Docker volume, served at `/uploads/*`.

### Admin web
```powershell
flutter build web --release --base-href="/admin/" `
  --dart-define=API_BASE_URL=https://<your-domain>/api/v1 `
  --target=lib/main_admin.dart
```
Copy `build/web/*` to the server's `admin-web/` directory (served by nginx under `/admin/`).

### Android (Play Store)
```powershell
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://<your-domain>/api/v1
```
Release signing reads `android/key.properties` (keystore not committed). Bump `version:` in `pubspec.yaml` before each store upload.

The reverse proxy must route `/api/`, `/socket.io/`, and `/uploads/` to the backend, and serve the admin web build under `/admin/`. See `DEPLOYMENT.md` for the full nginx/CloudPanel setup.

---

## Key API endpoints

| Method | Endpoint | Who | Purpose |
|---|---|---|---|
| POST | `/api/v1/auth/student/login` | student | login (seat number + password) |
| GET | `/api/v1/exam/available` | student | list startable exams for the student's branch |
| GET | `/api/v1/exam/:id/session` | student | create/resume exam session (per-student window) |
| GET | `/api/v1/exam/:id/questions` | student | questions for the active session (no correct answers) |
| POST | `/api/v1/answers` | student | save/sync an answer |
| POST | `/api/v1/exam/:id/submit` | student | submit + grade (response respects visibility flags) |
| GET | `/api/v1/exam/:id/result` | student | result, gated by `showResults` / `showAnswers` |
| POST | `/api/v1/admin/uploads/question-image` | admin | upload question/choice image (≤2MB → WEBP) |
| CRUD | `/api/v1/admin/exams`, `/admin/students`, `/admin/exams/:id/questions` | admin | management |

All responses: `{ "success": true, "data": … }` or `{ "success": false, "error": { "code", "message" } }`.

---

## Documentation

- [`PROJECT_SUMMARY.md`](PROJECT_SUMMARY.md) — full feature inventory, constraints, deployment notes
- [`NEXT_STEPS.md`](NEXT_STEPS.md) — prioritized roadmap
- [`DEPLOYMENT.md`](DEPLOYMENT.md) — server setup details
- Privacy policy & terms: `legal/` (hosted under `/legal/` in production)

## License

Private project — all rights reserved.
