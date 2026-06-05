# Tawjihi Platform Project Memory

## Current Repo State

- Existing codebase started as a standalone Flutter student app at repo root.
- Updated product spec now requires a Node.js + Express + PostgreSQL backend, Docker deployment, and Flutter client integration.
- To avoid risky churn, the Flutter app remains in place for now instead of being moved into a `mobile/` subdirectory.
- Backend and ops files are being added around the current Flutter project.

## Scope Decisions

- Fix only changed requirements affecting previous Flutter phases:
  - backend base URL contract changes to `/api/v1`
  - student auth endpoint changes to `/auth/student/login`
  - refresh token support is required
  - secure refresh token storage is required in Flutter
- Start backend implementation from the updated Node.js architecture and carry it through phases 4 and 5.
- Admin panel implementation is deferred; backend APIs are prioritized first.

## Implemented Before This Update

- Flutter core infrastructure
- Flutter student auth flow
- Flutter student exam flow with offline answer persistence and timer

## In Progress

- Deepen backend tests beyond smoke coverage
- Add richer Prisma-backed repository mocking for service/controller tests
- Continue Flutter migration in Phase 6 for full refresh/logout UX and admin live monitoring client

## Known Deviations

- Repo does not yet match the requested `mobile/` directory layout.
- Existing Flutter app remains in the repo root temporarily.
- Backend Jest currently uses `--forceExit` because ESM test imports still leave open handles in this setup.
- Student result endpoint now follows the secure backend contract and does not expose per-question correct answers.

## Completed In This Turn

- Added root infra and ops files:
  `docker-compose.yml`, `docker-compose.prod.yml`, `nginx/`, `scripts/`, `.env.example`, `Makefile`
- Added backend Node.js + Express + TypeScript project under `backend/`
- Added Prisma schema and seed file for PostgreSQL 16
- Added backend config, logger, JWT, Redis, middleware, and app bootstrap
- Implemented backend modules:
  `auth`, `students`, `exams`, `questions`, `answers`, `sessions`, `results`, `monitoring`
- Added backend Jest configuration and baseline module tests
- Verified backend with:
  `npm run build`
  `npm test`
- Applied Flutter contract updates required by the backend change:
  `API_BASE_URL` env config
  secure token storage via `flutter_secure_storage`
  refresh-token interceptor with one retry on `401`
  student login endpoint changed to `/auth/student/login`
  session creation moved from login flow to `GET /exam/:id/session`
- Verified Flutter with:
  `flutter analyze`
  `flutter test`

## Next Work Items

- Add real integration tests with Supertest and mocked Prisma repositories
- Build the admin client in Phase 6
- Add Flutter logout flow and explicit expired-session UX
- Revisit full monorepo relocation if you want the Flutter app physically moved into `mobile/`

## Relevant Contracts

- Base API URL: `https://your-domain.com/api/v1`
- Student login: `POST /auth/student/login`
- Refresh: `POST /auth/refresh`
- Logout: `POST /auth/logout`
- Student current exam: `GET /exam/current`
- Student session: `GET /exam/:id/session`
- Save answer: `POST /answers`
- Sync answers: `POST /answers/sync`
- Submit exam: `POST /exam/:id/submit`
- Result: `GET /exam/:id/result`

## Deployment Notes

- Target server: Oracle Cloud Ubuntu 22.04 LTS or Oracle Linux 8/9
- Containers: `postgres`, `redis`, `backend`, `nginx`
- Reverse proxy handles API, Socket.io upgrades, and Flutter Web hosting
