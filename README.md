# Moweton

Voice-first journal & livecast platform.  
Mobile is a Flutter client that talks to a Go backend (API + worker) running on a Docker Compose stack (Postgres, Redis, LiveKit, Loki/Grafana).

## Status (November 2025)

- ✅ Flutter UI implemented for onboarding, auth, feed, episode detail, comments, recorder/publish, profile, topics, live host/listener.
- ✅ Custom logging (`AppLogger`) wired through navigation, providers and API client.
- ✅ Backend integration tests run against Docker stack (`docker-compose.test.yml`).
- ✅ Recording uses the native microphone via `record`, uploads to `/v1/episodes/dev`, and the Go API serves audio from `LOCAL_MEDIA_PATH`.
- ✅ Flutter integration smoke test (`integration_test/app_test.dart`) exercises onboarding → auth → feed and is wired into `scripts/test.*`.

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

Locally the API is exposed at `http://localhost:8080/v1` (production: `https://api.moweton.com/v1`).  
Seed data example: `docker compose exec postgres psql -U postgres -d postgres`.

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

## Roadmap snapshot

### Stage 2 (Backend/UI sync)
- ✅ Explore/Search hooked to `/v1/explore` + filters, caching, empty/error states.
- ✅ Author profiles wired to `/v1/me/profile`, social links editor.
- ✅ Paywall screen talks to Stripe/MonoPay/RevenueCat + portal hand-offs.
- ✅ Push service registers/unregisters devices, exposes status in Settings.
- ⏳ Audio hardening + S3 pipeline, auth refresh rotation (in progress).

### Stage 3 (AI/behavioral)
- ✅ Smart Inbox prototype (client-side digest/highlights + tests).
- ⏳ Move Smart Inbox to backend and feed API when worker is ready.
- ⏳ LiveKit reconnection/backoff (partially done) + Live transcripts, Smart Inbox + TL;DR, Smart Inbox in feed preview.

Everything else from previous docs lives here now; browse Git history for legacy notes.
