# ParkLocator

Monorepo for the ParkLocator platform.

## Structure
- apps/mobile — Flutter app (Very Good CLI)
- apps/api — NestJS backend
- apps/admin — Angular admin portal
- docs — Product, architecture, and sprint artifacts
- scripts — Utility scripts (devops, tooling)

## Getting Started
1) Tooling: install Flutter/Dart, Very Good CLI, Nest CLI, and Angular CLI.
2) Services: start PostGIS
   - `docker compose up -d db`
   - Apple Silicon is supported via `platform: linux/amd64` in compose (qemu emulation); expect the first pull to take a few minutes.
   - Stop when done: `docker compose down`
   - DB defaults: user `parklocator`, password `parklocator`, db `parklocator`, port `5432`.
3) Run apps
   - Mobile (Flutter): `cd apps/mobile && flutter run --flavor development -t lib/main_development.dart`
   - API (Nest): `cd apps/api && npm run start:dev` (served on port 3000)
   - Admin (Angular): `cd apps/admin && npm start` (served on port 4200)
4) Tests/checks
   - Mobile: `cd apps/mobile && flutter test`
   - API: `cd apps/api && npm run lint && npm test`
   - Admin: `cd apps/admin && npm run test -- --watch=false`

Refer to docs for detailed requirements.
