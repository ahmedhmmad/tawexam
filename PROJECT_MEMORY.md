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

- Add backend monorepo structure under `backend/`
- Add Docker, Nginx, server setup, deploy, backup, and root env files
- Add Prisma schema and backend core bootstrapping
- Implement backend auth, students, exams, questions, answers, sessions, results, and monitoring
- Update Flutter only where the new backend contract changed prior work

## Known Deviations

- Repo does not yet match the requested `mobile/` directory layout.
- Existing Flutter app remains in the repo root temporarily.
- Backend verification will depend on installing Node dependencies and Prisma client generation.

## Next Work Items

- Finish backend infrastructure and module wiring
- Add Jest and Supertest coverage for critical flows
- Update Flutter auth/network/token handling for refresh token support
- Add admin live monitoring client integration in Flutter Web phase later

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
