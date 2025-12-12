# ParkLocator

Monorepo for the ParkLocator platform.

## Structure
- apps/mobile — Flutter app (Very Good CLI)
- apps/api — NestJS backend
- apps/admin — Angular admin portal
- docs — Product, architecture, and sprint artifacts
- scripts — Utility scripts (devops, tooling)

## Getting Started (bootstrap outline)
1) Install CLIs: Flutter/Dart, Very Good CLI, Nest CLI, Angular CLI.
2) Scaffold apps:
   - `very_good create app mobile` (in apps/mobile)
   - `nest new api` (in apps/api)
   - `ng new admin` (in apps/admin)
3) Infrastructure: add `docker-compose.yml` with PostGIS.
4) Run builds: `flutter test`, `npm run test` (api), `npm test` (admin).

Refer to docs for detailed requirements.
