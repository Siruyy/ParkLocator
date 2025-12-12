# ParkLocator

Monorepo for the ParkLocator platform.

## Structure
- apps/mobile — Flutter app (Very Good CLI)
- apps/api — NestJS backend
- apps/admin — Angular admin portal
- docs — Product, architecture, and sprint artifacts
- scripts — Utility scripts (devops, tooling)

## Getting Started
1) Install CLIs: Flutter/Dart, Very Good CLI, Nest CLI, Angular CLI.
2) Scaffolded apps (already in repo):
   - Flutter: `apps/mobile`
   - NestJS: `apps/api`
   - Angular: `apps/admin`
3) Infrastructure: `docker-compose.yml` (PostGIS) — start with `docker-compose up -d`.
4) Build/verify:
   - `cd apps/mobile && flutter test`
   - `cd apps/api && npm run build && npm test`
   - `cd apps/admin && npm run build`
5) Environment: database defaults (compose) — user `parklocator`, password `parklocator`, db `parklocator`, port `5432`.

Refer to docs for detailed requirements.
