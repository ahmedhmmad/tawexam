# TawExam Platform — Project Summary

> Last updated: June 8, 2026

## Overview

TawExam (توجيهي) is an offline-first electronic exam platform for Palestinian Tawjihi (high school) students. It enables admins to create timed multiple-choice exams and students to take them on a mobile app with full offline support.

---

## Tech Stack

### Backend
- **Runtime**: Node.js 20 (Alpine)
- **Language**: TypeScript
- **Framework**: Express.js
- **ORM**: Prisma
- **Database**: PostgreSQL 16
- **Cache/Sessions**: Redis 7
- **Auth**: JWT (RS256, access 15min + refresh 7d)
- **Real-time**: Socket.IO (admin monitoring)
- **File parsing**: xlsx (Excel imports)
- **Validation**: Zod
- **Security**: bcrypt, helmet, CORS, compression

### Mobile App (Students)
- **Framework**: Flutter 3.44 (Dart 3.12)
- **State management**: flutter_bloc / Cubit
- **DI**: get_it
- **Local storage**: Hive (encrypted)
- **Secure storage**: flutter_secure_storage (Keychain/EncryptedSharedPreferences)
- **HTTP**: Dio (with auth interceptor + auto-refresh)
- **Connectivity**: connectivity_plus
- **Functional**: dartz (Either for error handling)

### Admin Panel (Web)
- **Framework**: Flutter Web (Material 3)
- **Entry point**: `lib/main_admin.dart`
- **RTL Arabic interface**
- **Excel uploads** for students and questions

### Infrastructure
- **Server**: Ubuntu 22.04 on Oracle Cloud (130.61.16.114)
- **Domain**: tawjihi.megaserv.xyz (HTTPS via Let's Encrypt)
- **Reverse proxy**: CloudPanel nginx
- **Containers**: Docker Compose
  - postgres (port 5432)
  - redis (port 6379)
  - backend (port 3003)
- **Admin web** served from `/admin/` path (CloudPanel nginx)
- **Static legal pages** under `/legal/`

---

## Features Implemented

### Authentication
- Student login by seat number + password (bcrypt)
- Admin login with role-based access (SUPER_ADMIN / EXAM_MANAGER / VIEWER)
- JWT access + refresh tokens, refresh stored in Redis
- Auto-refresh on 401 via Dio interceptor
- Session persistence (cached student in Hive, auto-login on app restart)
- Logout clears tokens and cached session

### Admin Panel
- **Exam Management**
  - Create / edit / delete exams (any status)
  - Date/time pickers, duration, passing score, max attempts
  - Branch multi-select chips (علمي/أدبي/شرعي/صناعي)
  - Toggles: showResults, showAnswers, "تفعيل فوري" (immediate activation)
  - Status transitions (DRAFT → SCHEDULED → ACTIVE → COMPLETED → ARCHIVED)
  - Compact card UI with alternating colors
  - Search by name/status
- **Student Management**
  - Add / edit / delete / bulk-delete students
  - Reset password
  - Import via Excel (with branch pre-selection dialog)
  - Export to Excel
  - Filter by branch + search
  - Pagination (25/page)
- **Question Management**
  - Manual question creation (4 choices, mark correct)
  - Excel bulk upload with template download
  - List/view questions per exam
  - Edit / delete questions
- **Results**
  - Per-attempt results table (each session is one row)
  - Columns: name, seat number, branch, attempt #, status, score, correct/total, time
  - Excel export
  - Question template download
  - Status: SUBMITTED / IN_PROGRESS / EXPIRED / FORCE_ENDED

### Student Mobile App
- **Branded splash** (native + Flutter) with gradient background
- **Branch-colored header** (علمي=blue / أدبي=green / شرعي=purple / صناعي=orange)
- **Home dashboard**
  - Welcome with student name + seat + branch badge
  - Active exams list (multiple cards)
  - Past exams history
  - Pull-to-refresh
- **Exam flow**
  - Instructions page (duration, question count, rules)
  - Question page with timer, navigation, palette
  - Flag for review
  - Auto-save answers locally (Hive) before sync
  - Submit confirmation with answered/unanswered count
  - Result page (score-only, no answer details)
- **Offline support**
  - Answers saved locally instantly
  - Background sync via Dio
  - Exam questions cached for offline access
  - Exam window-based timer (per exam, not per attempt)

### Backend Logic
- **Per-student attempt counting** (only SUBMITTED/EXPIRED count, IN_PROGRESS doesn't)
- **Branch-aware exam discovery** (`/exam/available` returns all matching exams)
- **Session reuse**: returns existing IN_PROGRESS session, creates new for non-active
- **Grading on submit**: saves answers from request body before grading
- **Result visibility flags**: backend respects `showResults` and `showAnswers`
- **Audit logging**: all admin write operations
- **Health check**: `/health` endpoint

---

## Special Requirements / Constraints

- **Arabic UI throughout** with RTL layout (Directionality)
- **Gaza timezone (UTC+3)** — dates use device local time, no manual offset (the device is assumed to be in Gaza)
- **Branches**: Fixed list علمي/أدبي/شرعي/صناعي, dropdown selection (no free typing)
- **Session persistence**: Student stays logged in across app restarts (critical for unstable internet during exams)
- **Exam-window timer**: Timer runs based on the original exam start time, not per session, so a student who quits at 30:33 elapsed gets only the remaining time on retry
- **Result privacy**: Students see only their score; correct answer details are hidden unless admin enables `showAnswers`
- **Per-student attempts**: One student's attempt count doesn't affect another student
- **Offline-first**: Answers are persisted locally first, then synced; the app must work without internet during the exam
- **Admin app ID**: `com.tawjihi.exam`, version 1.1.2 (versionCode 6)
- **Min Android SDK**: 21 (Android 5.0+), Target SDK: 35
- **Performance**: bcrypt rounds 10, gzip compression, 30s Dio timeouts, connection pooling
- **Rate limiting**: Currently disabled (was causing test issues)
- **Legal pages**: Privacy policy and terms of service hosted at `https://tawjihi.megaserv.xyz/legal/`

---

## Deployment

### Backend
```bash
cd /opt/tawjihi && git pull origin main && docker compose up -d --build backend
```

### Admin Web
Build locally (Windows):
```powershell
flutter build web --release --base-href="/admin/" \
  --dart-define=API_BASE_URL=https://tawjihi.megaserv.xyz/api/v1 \
  --target=lib/main_admin.dart
```
Then SFTP `build/web/*` to `/opt/tawjihi/admin-web/`.

### Mobile App (Play Store)
```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://tawjihi.megaserv.xyz/api/v1
```
Output: `build/app/outputs/bundle/release/app-release.aab`

Keystore at `keystore/tawjihi-release.jks` (alias: tawjihi, password: tawjihi2026).

---

# Next Section: Image Support for Questions and Choices

## Requirement

Allow questions and answer choices to optionally include an image, so subjects like math, science, and biology can show diagrams, formulas, and figures.

## Scope

### Database (Prisma)
Add nullable `imageUrl` field to:
- `Question.imageUrl: String?`
- `Choice.imageUrl: String?`

### Backend
1. **Image upload endpoint**
   - `POST /admin/uploads/question-image` (multipart/form-data)
   - Accepts: PNG, JPG, JPEG, WEBP (max 2MB each)
   - Stores in `/app/uploads/questions/{uuid}.{ext}`
   - Returns: `{ url: "/uploads/questions/{uuid}.ext" }`
2. **Static serving**: Express serves `/uploads/*` from the volume-mounted directory
3. **Validation**: image MIME type check, size limit, dimension limit (e.g., max 1920×1920)
4. **Optional cleanup**: when a question is deleted, delete its image and its choices' images
5. **Excel import**: support an `image_url` column for question and `choice_a_image` ... `choice_d_image` columns for choices

### Admin Panel
1. **Question form**
   - Add image picker for the question (with preview)
   - Add image picker per choice (A, B, C, D) with preview
   - Upload image → get URL → store in form state
   - Show existing image when editing, with "remove" option
2. **Question list**
   - Show small thumbnail next to questions that have images
3. **Excel template**
   - Add `image_url` and `choice_a_image`...`choice_d_image` columns

### Mobile App
1. **Question entity**: add `imageUrl: String?`
2. **Choice / AnswerOption entity**: add `imageUrl: String?`
3. **Models**: parse `imageUrl` from JSON
4. **Question page UI**
   - Display the question image above the text (if present), with `Image.network` and a loading placeholder
   - Display choice image to the start of each choice tile (if present)
   - Cache images locally so offline review works (use `cached_network_image` or pre-download at session start)
5. **Pre-load**: during `getQuestions`, prefetch all image URLs into Flutter image cache for offline access

### File Structure (proposed)
```
backend/
  uploads/
    questions/
      {uuid}.png
```

### Storage Considerations
- Mount `/app/uploads` as a Docker volume (already done as `backend_uploads`)
- Total expected size: ~10MB per exam × 100 exams = 1GB max
- Images served via the same backend (no CDN needed initially)
- Optionally, later move to S3/Cloudflare R2 for scalability

### Open Questions
1. **Image format support**: PNG/JPG/WEBP only, or also SVG?
2. **Maximum size**: 2MB seems reasonable; should we allow larger?
3. **Resizing**: Should the backend auto-resize uploaded images to a max dimension to save bandwidth?
4. **Excel template image format**: Embedded images in Excel cells, or just URLs in cells?
5. **Offline strategy**: Pre-download all images at exam start, or lazy-load with cache?

### Estimated Effort
- Backend changes (schema, upload endpoint, static serving, validation): ~3-4 hours
- Admin panel UI (image pickers, previews, upload flow): ~4-5 hours
- Mobile app (rendering, caching): ~3-4 hours
- Testing + polish: ~2 hours
- **Total: ~12-15 hours of focused work**
