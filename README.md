# AmunX

Voice-first journal & livecast platform.  
Mobile is now a Flutter app that talks to a Go backend (API + worker) running on a Docker Compose stack (Postgres, Redis, LiveKit, Loki/Grafana).

## Status (November 2025)

- ✅ Flutter UI implemented for onboarding, auth, feed, episode detail, comments, recorder/publish, profile, topics, live host/listener.
- ✅ Custom logging (`AppLogger`) wired through navigation, providers and API client.
- ✅ Backend integration tests run against Docker stack (`docker-compose.test.yml`).
- ⚠️ Recording is still mocked: audio capture/upload + magic-link auth must be wired to real backend before release.
- ⚠️ Mobile integration tests are missing; only backend has automated coverage.

## Repository layout

```
backend/         Go API + worker, migrations, scripts
configs/         Observability configs (Grafana/Loki etc.)
docker-compose*  Local stack definitions
mobile/          Flutter client (lib/, android/, scripts/)
design/UX_UI...  Figma export & reference components
scripts/         Cross-platform helpers (tests, builds, flutter install)
```

## Prerequisites

- Flutter 3.24+ / Dart 3.4+ (`scripts/install-flutter.ps1` sets up on Windows).
- Go 1.22+
- Docker & Docker Compose
- Make / Bash (or PowerShell equivalents) for helper scripts.

## Backend

```bash
# 1. Environment
cp backend/.env.example backend/.env

# 2. Dependencies
cd backend
go mod download

# 3. Local infra
cd ..
docker compose up -d        # Postgres, Redis, LiveKit, Loki/Grafana, API, worker

# 4. Migrations
./scripts/migrate.sh up     # or scripts/migrate.ps1 on Windows

# 5. Tests
./scripts/test.sh           # (Linux/macOS)
./scripts/test.ps1          # (Windows)
```

The API is exposed at `http://localhost:8080/v1`. Seed data can be inserted via `docker exec amunx-postgres-1 psql ...`.

## Mobile (Flutter)

```bash
cd mobile
flutter pub get

# Run on emulator / device
flutter run -d emulator-5554

# Build debug APK
flutter build apk --debug
```

Notes:
- `scripts/install-flutter.ps1` adds Flutter to `C:\src\flutter` and updates PATH.
- Android builds expect SDK 34+ with hardware acceleration enabled; the repo already sets `android.useAndroidX=true`.
- Logging is visible via `flutter run` (look for `App:` / `Feed:` etc.).

## Stack verification

1. Start Docker services (`docker compose up -d`).
2. Insert sample episodes (see `backend/internal/http/episode_handlers.go` for schema).
3. Run `flutter run` → log in with any email (dev mode auto-logs you in) → verify feed, episode detail, comments, recorder/publish flows.
4. Backend tests: `./scripts/test.sh` spins up the test stack (`docker-compose.test.yml`) and executes Go integration suite.

## Open tasks before production

- **Audio pipeline**: swap the mocked recorder for `record`/`audio_service`, upload audio to `/v1/episodes` + `/finalize`, and expose playback URLs in feed.
- **Authentication**: current auth screen bypasses backend (dev token). Hook up real magic-link verification and session refresh.
- **Mobile integration tests**: add `integration_test/` suite that covers login → record → publish → feed/comment flows, and wire it into CI.
- **Live features**: connect Live Host/Listener screens to LiveKit events (currently UI-only).
- **Content moderation & analytics**: ensure backend configs (Loki/Grafana) match production requirements once telemetry is finalized.

Everything else from previous documentation was consolidated here to keep a single source of truth. Refer to Git history if you need any removed notes.
